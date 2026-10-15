export 'client.dart';
export 'models.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

// FFI C-ABI Native Bindings
@Native<Int32 Function(Pointer<Utf8>)>(symbol: 'rqbit_start')
external int _rqbitStart(Pointer<Utf8> configJson);

@Native<Int32 Function()>(symbol: 'rqbit_stop')
external int _rqbitStop();

@Native<Int32 Function()>(symbol: 'rqbit_is_running')
external int _rqbitIsRunning();

@Native<Int32 Function()>(symbol: 'rqbit_get_port')
external int _rqbitGetPort();

@Native<Pointer<Utf8> Function()>(symbol: 'rqbit_last_error')
external Pointer<Utf8> _rqbitLastError();

@Native<Void Function(Pointer<Utf8>)>(symbol: 'rqbit_free_str')
external void _rqbitFreeStr(Pointer<Utf8> ptr);

String? _getRustLastError() {
  final ptr = _rqbitLastError();
  if (ptr == nullptr) return null;
  try {
    return ptr.toDartString();
  } finally {
    _rqbitFreeStr(ptr);
  }
}

/// Exception thrown when rqbit operations fail.
class RqbitException implements Exception {
  final String message;
  final int? errorCode;

  const RqbitException(this.message, [this.errorCode]);

  @override
  String toString() => 'RqbitException: $message (code: $errorCode)';
}

/// Controller for the embedded rqbit HTTP service.
class RqbitServer {
  final int port;
  final Uri url;
  bool _isStopped = false;

  RqbitServer._({required this.port, required this.url});

  /// Returns the currently running server instance in this process if already started, or null.
  ///
  /// Useful for Flutter Hot Restart, where Dart memory is reset while the underlying native
  /// Rust daemon stays alive in the host process.
  static RqbitServer? current({String host = '127.0.0.1'}) {
    if (_rqbitIsRunning() == 1) {
      final port = _rqbitGetPort();
      if (port > 0) {
        final normalizedHost = (host == '0.0.0.0' || host == '::')
            ? '127.0.0.1'
            : host;
        return RqbitServer._(
          port: port,
          url: Uri.parse('http://$normalizedHost:$port/'),
        );
      }
    }
    return null;
  }

  /// Starts the rqbit HTTP service if not already running, or attaches to
  /// the existing running service in the current process.
  static Future<RqbitServer> startOrAttach({
    required String downloadDir,
    String bindAddr = '127.0.0.1:0',
    String? dhtPersistencePath,
  }) async {
    final host = bindAddr.split(':').first;
    final existing = current(host: host);
    if (existing != null) {
      return existing;
    }
    return start(
      downloadDir: downloadDir,
      bindAddr: bindAddr,
      dhtPersistencePath: dhtPersistencePath,
      attachIfRunning: true,
    );
  }

  /// Starts the rqbit HTTP service in the background and returns its server controller.
  ///
  /// [downloadDir]: Path to the directory where downloaded torrents are stored.
  /// [bindAddr]: Optional socket address to bind, defaults to '127.0.0.1:0'.
  /// [dhtPersistencePath]: Path to persist DHT routing table. Defaults to
  /// `<downloadDir>/.rqbit/dht.json`. Pass an empty string `""` to disable persistence.
  /// [attachIfRunning]: If true, reconnects to the existing server instance if already running
  /// instead of throwing an error.
  static Future<RqbitServer> start({
    required String downloadDir,
    String bindAddr = '127.0.0.1:0',
    String? dhtPersistencePath,
    bool attachIfRunning = false,
  }) async {
    final host = bindAddr.split(':').first;
    if (attachIfRunning) {
      final existing = current(host: host);
      if (existing != null) {
        return existing;
      }
    }

    final config = <String, dynamic>{
      'download_dir': downloadDir,
      'bind_addr': bindAddr,
      'dht_persistence': ?dhtPersistencePath,
    };
    final jsonStr = jsonEncode(config);
    final cJson = jsonStr.toNativeUtf8();

    try {
      final res = _rqbitStart(cJson);
      if (res <= 0) {
        // If error is code -6 (already running) and attachIfRunning is true, recover gracefully.
        if (res == -6 && attachIfRunning) {
          final existing = current(host: host);
          if (existing != null) {
            return existing;
          }
        }
        final err = _getRustLastError() ?? 'Unknown error';
        throw RqbitException('Failed to start rqbit server: $err', res);
      }

      final port = res;
      final normalizedHost = (host == '0.0.0.0' || host == '::')
          ? '127.0.0.1'
          : host;
      final url = Uri.parse('http://$normalizedHost:$port/');

      return RqbitServer._(port: port, url: url);
    } finally {
      malloc.free(cJson);
    }
  }

  /// Returns whether the server is currently running.
  bool get isRunning => !_isStopped && _rqbitIsRunning() == 1;

  /// Gracefully stops the rqbit HTTP service.
  Future<void> stop() async {
    if (_isStopped) return;
    _isStopped = true;
    final res = _rqbitStop();
    if (res != 0 && res != -1) {
      final err = _getRustLastError() ?? 'Unknown error';
      throw RqbitException('Failed to stop rqbit server: $err', res);
    }
  }
}
