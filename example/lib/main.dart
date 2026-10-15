import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rqbitx/rqbitx.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const BentoDemoApp());
}

class BentoDemoApp extends StatefulWidget {
  const BentoDemoApp({super.key});

  @override
  State<BentoDemoApp> createState() => _BentoDemoAppState();
}

class _BentoDemoAppState extends State<BentoDemoApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _cycleTheme() {
    setState(() {
      switch (_themeMode) {
        case ThemeMode.system:
          _themeMode = ThemeMode.light;
          break;
        case ThemeMode.light:
          _themeMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          _themeMode = ThemeMode.system;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFFF1F3F7),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121418),
        cardColor: const Color(0xFF1E222B),
      ),
      home: BentoExampleApp(themeMode: _themeMode, onToggleTheme: _cycleTheme),
    );
  }
}

class BentoExampleApp extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback? onToggleTheme;

  const BentoExampleApp({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onToggleTheme,
  });

  @override
  State<BentoExampleApp> createState() => _BentoExampleAppState();
}

class _BentoExampleAppState extends State<BentoExampleApp> {
  RqbitServer? _server;
  String _status = 'Starting...';
  String _response = '';
  bool _loading = false;
  bool _addingTorrent = false;
  bool _resolvingMetadata = false;
  bool _deletingTorrent = false;

  late final Player _player;
  late final VideoController _videoController;

  Timer? _metadataPollTimer;

  final TextEditingController _magnetController = TextEditingController(
    text: 'magnet:?xt=urn:btih:4EZLKDYRLJAGQDXSIIMYEDLBC5V7ZTO4&dn=&tr=http%3A%2F%2F104.143.10.61%3A8000%2Fannounce&tr=udp%3A%2F%2F104.143.10.61%3A8000%2Fannounce&tr=http%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=http%3A%2F%2Ftracker3.itzmx.com%3A6961%2Fannounce&tr=http%3A%2F%2Ftracker4.itzmx.com%3A2710%2Fannounce&tr=http%3A%2F%2Ftracker.publicbt.com%3A80%2Fannounce&tr=http%3A%2F%2Ftracker.prq.to%2Fannounce&tr=http%3A%2F%2Fopen.acgtracker.com%3A1096%2Fannounce&tr=https%3A%2F%2Ft-115.rhcloud.com%2Fonly_for_ylbud&tr=http%3A%2F%2Ftracker1.itzmx.com%3A8080%2Fannounce&tr=http%3A%2F%2Ftracker2.itzmx.com%3A6961%2Fannounce&tr=udp%3A%2F%2Ftracker1.itzmx.com%3A8080%2Fannounce&tr=udp%3A%2F%2Ftracker2.itzmx.com%3A6961%2Fannounce&tr=udp%3A%2F%2Ftracker3.itzmx.com%3A6961%2Fannounce&tr=udp%3A%2F%2Ftracker4.itzmx.com%3A2710%2Fannounce&tr=http%3A%2F%2Fnyaa.tracker.wf%3A7777%2Fannounce&tr=http%3A%2F%2Fopentracker.acgnx.se%2Fannounce&tr=http%3A%2F%2Ftr.bangumi.moe%3A6969%2Fannounce&tr=http%3A%2F%2Ftracker.ktxp.com%3A6868%2Fannounce&tr=http%3A%2F%2Ftracker.ktxp.com%3A7070%2Fannounce&tr=http%3A%2F%2Fshare.camoe.cn%3A8080%2Fannounce&tr=http%3A%2F%2F61.154.116.205%3A8000%2Fannounce&tr=http%3A%2F%2Fbt.rghost.net%3A80%2Fannounce&tr=http%3A%2F%2Ft.acg.rip%3A6699%2Fannounce&tr=http%3A%2F%2F94.228.192.98%2Fannounce&tr=http%3A%2F%2Ftracker.btcake.com%2Fannounce&tr=http%3A%2F%2Fbtfile.sdo.com%3A6961%2Fannounce&tr=http%3A%2F%2Fexodus.desync.com%3A6969%2Fannounce&tr=http%3A%2F%2Ftracker3.torrentino.com%2Fannounce&tr=http%3A%2F%2Ftracker2.torrentino.com%2Fannounce&tr=http%3A%2F%2Fpubt.net%3A2710%2Fannounce&tr=http%3A%2F%2Fbigfoot1942.sektori.org%3A6969%2Fannounce&tr=http%3A%2F%2Ft.nyaatracker.com%2Fannounce&tr=http%3A%2F%2Fbt.sc-ol.com%3A2710%2Fannounce&tr=https%3A%2F%2Ftracker.zhuqiy.com%3A443%2Fannounce&tr=https%3A%2F%2Ftracker.yemekyedim.com%3A443%2Fannounce&tr=https%3A%2F%2Ftracker.nekomi.cn%3A443%2Fannounce&tr=https%3A%2F%2Ftracker.moeking.me%3A443%2Fannounce&tr=https%3A%2F%2Ftorrents.tmtime.dev%3A443%2Fannounce&tr=https%3A%2F%2Ftracker.anibt.net%2Fannounce&tr=http%3A%2F%2Ftracker.tfile.me%2Fannounce',
  );

  RqbitClient? _client;
  String _currentTorrentId = '';
  String _currentTorrentName = '';
  List<TorrentFile> _torrentFiles = [];

  // Currently playing file state
  String _playingFileName = '';
  String _playingStreamUrl = '';

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    // 首次打开立刻自动启动或恢复重连 rqbit 服务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startServerAuto();
    });
  }

  @override
  void dispose() {
    _metadataPollTimer?.cancel();
    _player.dispose();
    _magnetController.dispose();
    super.dispose();
  }

  /// 解析默认存储路径：优先使用 getDownloadsDirectory，失败时自动以 getTemporaryDirectory 兜底
  Future<Directory> _resolveDownloadDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        final target = Directory('${downloads.path}/rqbitx_downloads');
        if (!target.existsSync()) {
          target.createSync(recursive: true);
        }
        return target;
      }
    } catch (_) {}

    final temp = await getTemporaryDirectory();
    final target = Directory('${temp.path}/rqbitx_downloads');
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }
    return target;
  }

  Future<void> _startServerAuto() async {
    setState(() {
      _loading = true;
      _status = 'Connecting...';
      _response = '正在初始化连接或启动 rqbit 引擎...';
    });
    try {
      // 1. 若热重启或进程内已有实例存活，直接无缝重新接管
      final existing = RqbitServer.current();
      if (existing != null) {
        setState(() {
          _server = existing;
          _client = RqbitClient(baseUrl: existing.url.toString());
          _status = 'Online';
          _response = '已恢复连接至已在运行的 rqbit 服务: ${existing.url}';
        });
        await _restoreActiveTorrents();
        return;
      }

      // 2. 否则冷启动新服务 (使用 path_provider 解析默认目录)
      final downloadDir = await _resolveDownloadDirectory();
      final server = await RqbitServer.start(downloadDir: downloadDir.path);
      setState(() {
        _server = server;
        _client = RqbitClient(baseUrl: server.url.toString());
        _status = 'Online';
        _response = 'rqbit 服务自启动成功:\n${server.url}\n存储路径: ${downloadDir.path}';
      });
      await _probeHttp();
    } catch (e, st) {
      setState(() {
        _status = 'Error';
        _response = '启动失败:\n$e\n$st';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _restoreActiveTorrents() async {
    final client = _client;
    if (client == null) return;
    try {
      final res = await client.listTorrents();
      if (res.torrents.isNotEmpty) {
        final first = res.torrents.first;
        final id = (first.id?.toString() ?? first.infoHash);
        final name = first.name ?? '';
        if (id.isNotEmpty) {
          setState(() {
            _currentTorrentId = id;
            _currentTorrentName = name;
          });
          await _fetchTorrentDetails();
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleServer() async {
    final server = _server;
    if (server == null || !server.isRunning) {
      await _startServerAuto();
    } else {
      setState(() {
        _loading = true;
        _status = 'Stopping...';
      });
      _metadataPollTimer?.cancel();
      _player.stop();
      try {
        await server.stop();
        setState(() {
          _server = null;
          _client = null;
          _status = 'Offline';
          _response = '服务已成功停止';
          _currentTorrentId = '';
          _currentTorrentName = '';
          _torrentFiles.clear();
          _playingFileName = '';
          _playingStreamUrl = '';
        });
      } catch (e) {
        setState(() {
          _response = '停止服务出错: $e';
        });
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _probeHttp() async {
    final client = _client;
    if (client == null) {
      setState(() {
        _response = '错误: 服务未运行或 Client 未初始化';
      });
      return;
    }
    setState(() {
      _loading = true;
      _response = '正在请求 RqbitClient.listTorrents() ...';
    });
    try {
      final res = await client.listTorrents();
      setState(() {
        _response =
            'HTTP 探测成功 (Dio 强类型响应):\n已载入种子任务数: ${res.torrents.length}\n${jsonEncode(res.toJson())}';
      });
    } catch (e) {
      setState(() {
        _response = 'HTTP 探测请求失败:\n$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _addMagnet() async {
    final client = _client;
    if (client == null) {
      setState(() {
        _response = '错误: 请先启动 rqbit 服务';
      });
      return;
    }

    final magnet = _magnetController.text.trim();
    if (magnet.isEmpty) {
      setState(() {
        _response = '请输入有效的磁力链接';
      });
      return;
    }

    setState(() {
      _addingTorrent = true;
      _response = '正在通过 RqbitClient 添加种子任务...';
      _torrentFiles = [];
      _currentTorrentName = '';
      _currentTorrentId = '';
      _resolvingMetadata = true;
    });

    try {
      final res = await client.addTorrent(
        magnet,
        options: const AddTorrentOptions(overwrite: true),
      );

      final id = (res.id ?? 0).toString();
      final name = res.details.name ?? '';

      setState(() {
        _currentTorrentId = id;
        _currentTorrentName = name;
        _response = '种子添加成功 (ID: $id, Hash: ${res.details.infoHash})';
      });

      _startMetadataPolling();
    } catch (e) {
      setState(() {
        _resolvingMetadata = false;
        _response = '添加种子请求异常:\n$e';
      });
    } finally {
      setState(() {
        _addingTorrent = false;
      });
    }
  }

  void _startMetadataPolling() {
    _metadataPollTimer?.cancel();
    _metadataPollTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      if (_currentTorrentId.isEmpty || !(_server?.isRunning ?? false)) {
        timer.cancel();
        return;
      }
      await _fetchTorrentDetails();
      if (_torrentFiles.isNotEmpty) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _resolvingMetadata = false;
          });
        }
      }
    });
  }

  Future<void> _fetchTorrentDetails() async {
    final client = _client;
    if (client == null || _currentTorrentId.isEmpty) {
      return;
    }

    try {
      final int id = int.tryParse(_currentTorrentId) ?? 0;
      final details = await client.getTorrentDetails(id);

      if (mounted) {
        setState(() {
          final torrentName = details.name;
          if (torrentName != null && torrentName.isNotEmpty) {
            _currentTorrentName = torrentName;
          }
          final files = details.files;
          if (files != null && files.isNotEmpty) {
            _torrentFiles = files;
            _resolvingMetadata = false;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _confirmAndDeleteTorrent() async {
    final taskName = _currentTorrentName.isNotEmpty
        ? _currentTorrentName
        : '任务 (#$_currentTorrentId)';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252)),
            SizedBox(width: 8),
            Text('删除任务与本地文件', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          '确定要删除「$taskName」吗？\n\n'
          '⚠️ 注意：此操作不仅会从后台移除任务，还会同步彻底删除本地磁盘已下载的全部切片与媒体文件，不可恢复。',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除任务并清除文件'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTorrent();
    }
  }

  Future<void> _deleteTorrent() async {
    final client = _client;
    if (client == null || _currentTorrentId.isEmpty) {
      return;
    }

    setState(() {
      _deletingTorrent = true;
      _response = '正在请求删除种子任务并清理本地物理文件...';
    });

    _metadataPollTimer?.cancel();
    _player.stop();

    try {
      final int id = int.tryParse(_currentTorrentId) ?? 0;
      await client.deleteTorrent(id);

      final deletedName = _currentTorrentName.isNotEmpty
          ? _currentTorrentName
          : _currentTorrentId;
      setState(() {
        _response = '种子任务已移除，本地文件已同步彻底清理: $deletedName';
        _currentTorrentId = '';
        _currentTorrentName = '';
        _torrentFiles.clear();
        _playingFileName = '';
        _playingStreamUrl = '';
        _resolvingMetadata = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除任务「$deletedName」及本地文件'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _response = '删除任务请求异常:\n$e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除任务失败: $e'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingTorrent = false;
        });
      }
    }
  }

  bool _isMediaFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.flv') ||
        lower.endsWith('.ts') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.ogg');
  }

  String _formatBytes(num bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _openPlayerModal(int fileIdx, String fileName) {
    final server = _server;
    if (server == null || !server.isRunning || _currentTorrentId.isEmpty) {
      return;
    }
    final streamUrl = server.url
        .resolve('/torrents/$_currentTorrentId/stream/$fileIdx')
        .toString();

    setState(() {
      _playingFileName = fileName;
      _playingStreamUrl = streamUrl;
      _response = '正在启动底部流式播放: $fileName\nURL: $streamUrl';
    });

    _player.open(Media(streamUrl));
    _player.play();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildPlayerBottomSheet(),
    ).whenComplete(() {
      _player.stop();
      if (mounted) {
        setState(() {
          _playingStreamUrl = '';
          _playingFileName = '';
        });
      }
    });
  }

  Widget _buildPlayerBottomSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag indicator bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Media title & Close button
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.movie_rounded,
                  color: Colors.blueAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _playingFileName.isEmpty ? '视频流播放' : _playingFileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'rqbit 实时范围切片流',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: '关闭播放器',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Video Player Screen
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Video(controller: _videoController),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Stream URL & Action Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _playingStreamUrl,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _playingStreamUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制播放流地址到剪贴板'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: '复制流地址',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeToggle() {
    IconData icon;
    String tooltip;
    switch (widget.themeMode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto_rounded;
        tooltip = '主题: 跟随系统 (点击切为浅色)';
        break;
      case ThemeMode.light:
        icon = Icons.light_mode_rounded;
        tooltip = '主题: 浅色 (点击切为深色)';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode_rounded;
        tooltip = '主题: 深色 (点击切为跟随系统)';
        break;
    }

    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
      ),
      onPressed: widget.onToggleTheme,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRunning = _server?.isRunning ?? false;
    final serverUrl = _server?.url.toString() ?? '---';
    final serverPort = _server?.port.toString() ?? '---';
    final hasTask = _currentTorrentId.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.waves,
                color: Colors.blueAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'rqbitx & MediaKit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Torrent Streaming Engine Demo',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [_themeToggle(), const SizedBox(width: 16)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unified Service Management Bento Tile (服务管理、断开、状态、链接复制)
            _bentoTile(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header: Title + Status Badge
                  Row(
                    children: [
                      Icon(
                        Icons.dns_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '服务管理',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _statusBadge(isRunning),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Metrics & State Summary (Port & Status)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '监听端口',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                serverPort,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '运行状态',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _status,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isRunning
                                      ? const Color(0xFF10B981)
                                      : colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Service Base URL & Copy Action
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            serverUrl,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          onPressed: isRunning
                              ? () {
                                  Clipboard.setData(
                                    ClipboardData(text: serverUrl),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('已复制服务地址到剪贴板'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              : null,
                          tooltip: '复制服务地址',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Action Row (Start / Disconnect & Probe HTTP)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRunning
                                ? const Color(0xFFFF5252)
                                : const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: _loading ? null : _toggleServer,
                          icon: Icon(
                            isRunning
                                ? Icons.power_settings_new_rounded
                                : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _loading ? '处理中...' : (isRunning ? '断开服务' : '启动服务'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(13),
                        ),
                        onPressed: isRunning ? _probeHttp : null,
                        icon: const Icon(Icons.network_check_rounded, size: 20),
                        tooltip: '探测 HTTP GET',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Magnet Input Bento Tile
            _bentoTile(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '添加磁力链接 (Magnet Link)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _magnetController,
                    maxLines: 2,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: '输入或粘贴 magnet:?xt=urn:btih:...',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => _magnetController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: (isRunning && !_addingTorrent)
                          ? _addMagnet
                          : null,
                      icon: _addingTorrent
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_task_rounded, size: 18),
                      label: Text(
                        _addingTorrent ? '正在提交...' : '添加种子任务',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Torrent Task & Files Bento Tile (仅在添加了任务后显示)
            if (hasTask) ...[
              const SizedBox(height: 14),
              _bentoTile(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_zip_outlined,
                          size: 18,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentTorrentName.isNotEmpty
                                ? _currentTorrentName
                                : '任务详情 (#$_currentTorrentId)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: Colors.blueAccent,
                          ),
                          onPressed: _fetchTorrentDetails,
                          tooltip: '刷新文件列表',
                        ),
                        IconButton(
                          icon: _deletingTorrent
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF5252),
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Color(0xFFFF5252),
                                ),
                          onPressed: _deletingTorrent
                              ? null
                              : _confirmAndDeleteTorrent,
                          tooltip: '删除任务与本地文件',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hash / ID: $_currentTorrentId',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),

                    // Resolving metadata spinner
                    if (_resolvingMetadata && _torrentFiles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '正在从 DHT / Peer 网络解析种子元数据...',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '获取到文件列表后将在此处呈现',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Files list
                    if (_torrentFiles.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text(
                            '文件列表',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '共 ${_torrentFiles.length} 项',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _torrentFiles.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: colorScheme.outlineVariant,
                        ),
                        itemBuilder: (ctx, idx) {
                          final f = _torrentFiles[idx];
                          final fileIdx = idx;
                          final fileName = f.name;
                          final length = f.length;
                          final isMedia = _isMediaFile(fileName);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isMedia
                                        ? Colors.blueAccent.withValues(
                                            alpha: 0.15,
                                          )
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isMedia
                                        ? Icons.movie_outlined
                                        : Icons.insert_drive_file_outlined,
                                    size: 18,
                                    color: isMedia
                                        ? Colors.blueAccent
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatBytes(length),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (isMedia)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () =>
                                        _openPlayerModal(fileIdx, fileName),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      '播放',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '文件',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5252),
                          side: const BorderSide(
                            color: Color(0xFFFF5252),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _deletingTorrent
                            ? null
                            : _confirmAndDeleteTorrent,
                        icon: _deletingTorrent
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF5252),
                                ),
                              )
                            : const Icon(
                                Icons.delete_forever_rounded,
                                size: 18,
                              ),
                        label: Text(
                          _deletingTorrent ? '正在删除并清理本地文件...' : '删除任务并清理本地文件',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Console / Probe Response Bento Tile
            _bentoTile(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '事件日志与响应',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _response.isEmpty ? '等待操作...' : _response,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: _response.isEmpty
                            ? colorScheme.outline
                            : colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 纯平无边框 Bento 卡片，零 boxShadow，直接取当前主题的 cardColor
  Widget _bentoTile({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }

  Widget _statusBadge(bool isRunning) {
    final color = isRunning ? const Color(0xFF10B981) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            isRunning ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
