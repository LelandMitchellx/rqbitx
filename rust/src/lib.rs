// rqbitx: Minimal FFI bindings to start and stop rqbit HTTP server
use std::ffi::{CStr, CString};
use std::net::SocketAddr;
use std::os::raw::c_char;
use std::path::PathBuf;
use std::sync::Mutex;
use std::thread;

use librqbit::api::Api;
use librqbit::dht::DhtPersistenceConfig;
use librqbit::http_api::{HttpApi, HttpApiOptions};
use librqbit::{DhtSessionConfig, Session, SessionOptions};
use librqbit_dualstack_sockets::TcpListener;
use tokio::runtime::Runtime;
use tokio::sync::watch;

static LAST_ERROR: Mutex<Option<String>> = Mutex::new(None);

fn set_last_error(err: String) {
    let clean = err.replace('\0', " ");
    if let Ok(mut g) = LAST_ERROR.lock() {
        *g = Some(clean);
    }
}

#[derive(Debug, serde::Deserialize)]
struct RqbitStartConfig {
    download_dir: String,
    #[serde(default = "default_bind_addr")]
    bind_addr: String,
    #[serde(alias = "dhtPersistencePath", alias = "dht_persistence_path", default)]
    dht_persistence: Option<String>,
}

fn default_bind_addr() -> String {
    "127.0.0.1:0".to_string()
}

struct RqbitContext {
    shutdown_tx: watch::Sender<bool>,
    thread_handle: Option<thread::JoinHandle<()>>,
    port: u16,
}

static SERVICE: Mutex<Option<RqbitContext>> = Mutex::new(None);

#[unsafe(no_mangle)]
pub extern "C" fn rqbit_last_error() -> *mut c_char {
    LAST_ERROR
        .lock()
        .ok()
        .and_then(|mut g| g.take())
        .and_then(|msg| CString::new(msg).ok())
        .map(CString::into_raw)
        .unwrap_or(std::ptr::null_mut())
}

#[unsafe(no_mangle)]
/// # Safety
/// ptr must be a valid pointer returned by rqbit_last_error or null.
pub unsafe extern "C" fn rqbit_free_str(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe { drop(CString::from_raw(ptr)) };
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rqbit_is_running() -> i32 {
    if SERVICE.lock().is_ok_and(|g| g.is_some()) {
        1
    } else {
        0
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rqbit_get_port() -> i32 {
    if let Ok(guard) = SERVICE.lock()
        && let Some(ref ctx) = *guard {
            return ctx.port as i32;
        }
    0
}

#[unsafe(no_mangle)]
/// # Safety
/// config_json must be a valid NUL-terminated UTF-8 JSON C-string.
pub unsafe extern "C" fn rqbit_start(config_json: *const c_char) -> i32 {
    let result = std::panic::catch_unwind(|| {
        if config_json.is_null() {
            set_last_error("config_json pointer is null".to_string());
            return -1;
        }

        let json_str = match unsafe { CStr::from_ptr(config_json) }.to_str() {
            Ok(s) => s,
            Err(e) => {
                set_last_error(format!("config_json is not valid UTF-8: {e}"));
                return -2;
            }
        };

        let config: RqbitStartConfig = match serde_json::from_str(json_str) {
            Ok(cfg) => cfg,
            Err(e) => {
                set_last_error(format!("failed to parse start config JSON: {e}"));
                return -3;
            }
        };

        if config.download_dir.trim().is_empty() {
            set_last_error("download_dir cannot be empty".to_string());
            return -4;
        }

        let mut guard = match SERVICE.lock() {
            Ok(g) => g,
            Err(_) => {
                set_last_error("failed to acquire SERVICE mutex".to_string());
                return -5;
            }
        };

        if guard.is_some() {
            set_last_error("rqbit HTTP service is already running".to_string());
            return -6;
        }

        let download_dir = PathBuf::from(config.download_dir.trim());
        if let Err(e) = std::fs::create_dir_all(&download_dir) {
            set_last_error(format!("failed to create download_dir: {e}"));
            return -7;
        }

        let bind_addr: SocketAddr = match config.bind_addr.parse() {
            Ok(a) => a,
            Err(e) => {
                set_last_error(format!("invalid bind_addr '{}': {e}", config.bind_addr));
                return -8;
            }
        };

        let runtime = match Runtime::new() {
            Ok(rt) => rt,
            Err(e) => {
                set_last_error(format!("failed to create tokio runtime: {e}"));
                return -9;
            }
        };

        // Resolve DHT persistence path.
        // On Android / mobile environments, librqbit's default DhtPersistenceConfig
        // uses directories::ProjectDirs::from("com", "rqbit", "dht"), which fails with
        // "cannot determine project directory for com.rqbit.dht" because standard Linux
        // XDG/$HOME dirs do not exist, crashing Session initialization.
        // Therefore, we MUST provide an explicit path under download_dir by default,
        // or allow callers to disable it by passing an empty string.
        let dht_path_buf = match config.dht_persistence {
            Some(ref s) => {
                let trimmed = s.trim();
                if trimmed.is_empty() {
                    None
                } else {
                    Some(PathBuf::from(trimmed))
                }
            }
            None => {
                Some(download_dir.join(".rqbit").join("dht.json"))
            }
        };

        let dht_persistence_config = dht_path_buf.map(|path| {
            if let Some(parent) = path.parent() {
                let _ = std::fs::create_dir_all(parent);
            }
            DhtPersistenceConfig {
                config_filename: Some(path),
                ..Default::default()
            }
        });

        let session = match runtime.block_on(Session::new_with_opts(
            download_dir,
            SessionOptions {
                fastresume: true,
                dht: Some(DhtSessionConfig {
                    persistence: dht_persistence_config,
                    ..Default::default()
                }),
                ..Default::default()
            },
        )) {
            Ok(s) => s,
            Err(e) => {
                set_last_error(format!("failed to initialize rqbit session: {e}"));
                return -10;
            }
        };

        let listener = match runtime
            .block_on(async { TcpListener::bind_tcp(bind_addr, Default::default()) })
        {
            Ok(l) => l,
            Err(e) => {
                set_last_error(format!("failed to bind TCP listener on {bind_addr}: {e}"));
                return -11;
            }
        };

        let port = listener.bind_addr().port();

        let api = Api::new(session.clone(), None, None);
        let http_api = HttpApi::new(
            api,
            Some(HttpApiOptions {
                read_only: false,
                allow_create: true,
                ..Default::default()
            }),
        );

        let (shutdown_tx, mut shutdown_rx) = watch::channel(false);

        let handle = thread::spawn(move || {
            runtime.block_on(async move {
                tokio::select! {
                    res = http_api.make_http_api_and_run(listener, None) => {
                        if let Err(e) = res {
                            eprintln!("rqbit HTTP service exited with error: {e:#}");
                        }
                    }
                    _ = shutdown_rx.wait_for(|&val| val) => {}
                }
                session.stop().await;
            });
        });

        *guard = Some(RqbitContext {
            shutdown_tx,
            thread_handle: Some(handle),
            port,
        });

        port as i32
    });

    match result {
        Ok(code) => code,
        Err(panic_payload) => {
            let msg = if let Some(s) = panic_payload.downcast_ref::<&str>() {
                s.to_string()
            } else if let Some(s) = panic_payload.downcast_ref::<String>() {
                s.clone()
            } else {
                "unknown panic".to_string()
            };
            set_last_error(format!("Rust Panic: {msg}"));
            -99
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rqbit_stop() -> i32 {
    let result = std::panic::catch_unwind(|| {
        let ctx = {
            if let Ok(mut guard) = SERVICE.lock() {
                guard.take()
            } else {
                None
            }
        };

        if let Some(mut ctx) = ctx {
            let _ = ctx.shutdown_tx.send(true);
            if let Some(handle) = ctx.thread_handle.take() {
                let _ = handle.join();
            }
            0
        } else {
            -1
        }
    });

    result.unwrap_or(-99)
}
