import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rqbitx/rqbitx.dart';

/// Lightweight mock adapter to simulate librqbit daemon HTTP responses.
class MockDaemonAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions options)> handlers =
      {};

  void on(
    String method,
    String path,
    ResponseBody Function(RequestOptions options) handler,
  ) {
    handlers['${method.toUpperCase()}:$path'] = handler;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method.toUpperCase()}:${options.uri.path}';
    final handler = handlers[key];
    if (handler != null) {
      return handler(options);
    }
    return ResponseBody.fromString(
      jsonEncode({'error': 'Not Found'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('RqbitClient (Dio-based) Contract Tests', () {
    late Dio dio;
    late MockDaemonAdapter adapter;
    late RqbitClient client;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:4242'));
      adapter = MockDaemonAdapter();
      dio.httpClientAdapter = adapter;
      client = RqbitClient(baseUrl: 'http://127.0.0.1:4242', dio: dio);
    });

    test('listTorrents parses TorrentListResponse', () async {
      adapter.on('GET', '/torrents', (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'torrents': [
              {
                'id': 0,
                'info_hash': 'abc123hash',
                'output_folder': '/downloads',
                'total_pieces': 100,
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final res = await client.listTorrents();
      expect(res.torrents.length, 1);
      expect(res.torrents.first.id, 0);
      expect(res.torrents.first.infoHash, 'abc123hash');
    });

    test('getTorrentDetails parses TorrentDetails with nested files', () async {
      adapter.on('GET', '/torrents/0', (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'id': 0,
            'info_hash': 'hash000',
            'name': 'DemoMovie',
            'output_folder': '/downloads',
            'total_pieces': 500,
            'files': [
              {
                'name': 'movie.mp4',
                'components': ['movie.mp4'],
                'length': 1024000,
                'included': true,
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final details = await client.getTorrentDetails(0);
      expect(details.id, 0);
      expect(details.name, 'DemoMovie');
      expect(details.files?.length, 1);
      expect(details.files?.first.name, 'movie.mp4');
    });

    test('addTorrent creates torrent with query params and body', () async {
      adapter.on('POST', '/torrents', (options) {
        expect(options.queryParameters['overwrite'], 'true');
        expect(options.queryParameters['only_files'], '0,1');
        return ResponseBody.fromString(
          jsonEncode({
            'id': 1,
            'details': {
              'id': 1,
              'info_hash': 'magnetHash',
              'output_folder': '/downloads',
              'total_pieces': 80,
            },
            'output_folder': '/downloads',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final resp = await client.addTorrent(
        'magnet:?xt=urn:btih:magnetHash',
        options: const AddTorrentOptions(overwrite: true, onlyFiles: [0, 1]),
      );

      expect(resp.id, 1);
      expect(resp.details.infoHash, 'magnetHash');
    });

    test('deleteTorrent executes POST /torrents/{id}/delete', () async {
      bool deleted = false;
      adapter.on('POST', '/torrents/1/delete', (options) {
        deleted = true;
        return ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await client.deleteTorrent(1);
      expect(deleted, isTrue);
    });

    test('pauseTorrent and startTorrent call correct endpoints', () async {
      bool paused = false;
      bool started = false;

      adapter.on('POST', '/torrents/2/pause', (options) {
        paused = true;
        return ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      adapter.on('POST', '/torrents/2/start', (options) {
        started = true;
        return ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await client.pauseTorrent(2);
      await client.startTorrent(2);

      expect(paused, isTrue);
      expect(started, isTrue);
    });

    test('throws RqbitClientException on 404 or server error', () async {
      expect(
        () => client.getTorrentDetails(999),
        throwsA(
          isA<RqbitClientException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('updateOnlyFiles sends correct JSON payload', () async {
      Map<String, dynamic>? receivedBody;
      adapter.on('POST', '/torrents/1/update_only_files', (options) {
        receivedBody = options.data is Map
            ? options.data as Map<String, dynamic>
            : jsonDecode(options.data.toString());
        return ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await client.updateOnlyFiles(1, [0, 2]);
      expect(receivedBody?['only_files'], [0, 2]);

      // Test with empty list (metadata only)
      await client.updateOnlyFiles(1, []);
      expect(receivedBody?['only_files'], isEmpty);
    });

    test('getTorrentStats parses TorrentStats from stats/v1', () async {
      adapter.on('GET', '/torrents/1/stats/v1', (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'state': 'live',
            'file_progress': [500],
            'progress_bytes': 500,
            'uploaded_bytes': 100,
            'total_bytes': 1000,
            'finished': false,
            'live': {
              'snapshot': {'fetched_bytes': 500, 'uploaded_bytes': 100},
              'download_speed': {'mbps': 3.5, 'human_readable': '3.50 MiB/s'},
              'upload_speed': {'mbps': 0.5, 'human_readable': '0.50 MiB/s'},
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final stats = await client.getTorrentStats(1);
      expect(stats.state, 'live');
      expect(stats.progressBytes, 500);
      expect(stats.totalBytes, 1000);
      expect(stats.progressFraction, 0.5);
      expect(stats.live?.downloadSpeed.mbps, 3.5);
      expect(stats.live?.downloadSpeed.humanReadable, '3.50 MiB/s');
    });

    test('getServerInfo retrieves server and api map', () async {
      adapter.on('GET', '/', (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'server': 'rqbit',
            'version': '9.0.1',
            'apis': {'GET /': 'api list'},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final info = await client.getServerInfo();
      expect(info.server, 'rqbit');
      expect(info.version, '9.0.1');
      expect(info.apis['GET /'], 'api list');
    });

    test('getSessionStats retrieves global statistics', () async {
      adapter.on('GET', '/stats', (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'counters': {
              'fetched_bytes': 1024,
              'uploaded_bytes': 512,
              'blocked_incoming': 0,
              'blocked_outgoing': 0,
            },
            'download_speed': {'mbps': 2.0, 'human_readable': '2.00 MiB/s'},
            'upload_speed': {'mbps': 1.0, 'human_readable': '1.00 MiB/s'},
            'peers': {
              'queued': 0,
              'connecting': 1,
              'live': 2,
              'live_tcp': 2,
              'live_utp': 0,
              'live_socks': 0,
              'seen': 5,
              'dead': 1,
              'not_needed': 0,
              'steals': 0,
            },
            'uptime_seconds': 3600,
            'connections': {
              'socks': {
                'v4': {'attempts': 0, 'successes': 0, 'errors': 0},
                'v6': {'attempts': 0, 'successes': 0, 'errors': 0},
              },
              'tcp': {
                'v4': {'attempts': 10, 'successes': 8, 'errors': 2},
                'v6': {'attempts': 0, 'successes': 0, 'errors': 0},
              },
              'utp': {
                'v4': {'attempts': 0, 'successes': 0, 'errors': 0},
                'v6': {'attempts': 0, 'successes': 0, 'errors': 0},
              },
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final stats = await client.getSessionStats();
      expect(stats.uptimeSeconds, 3600);
      expect(stats.counters.fetchedBytes, 1024);
      expect(stats.peers.liveTcp, 2);
    });

    test('getLimits and updateLimits manipulate session ratelimits', () async {
      adapter.on('GET', '/torrents/limits', (options) {
        return ResponseBody.fromString(
          jsonEncode({'upload_bps': 2048, 'download_bps': 4096}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final limits = await client.getLimits();
      expect(limits.uploadBps, 2048);
      expect(limits.downloadBps, 4096);

      dynamic sentData;
      adapter.on('POST', '/torrents/limits', (options) {
        sentData = options.data;
        return ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await client.updateLimits(
        const LimitsConfig(uploadBps: 1000, downloadBps: null),
      );
      expect(sentData['upload_bps'], 1000);
      expect(sentData['download_bps'], isNull);
    });

    test('setRustLog posts log filter string', () async {
      String? sentBody;
      adapter.on('POST', '/rust_log', (options) {
        sentBody = options.data.toString();
        return ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await client.setRustLog('trace,rqbit=debug');
      expect(sentBody, 'trace,rqbit=debug');
    });

    test('getDhtStats and getDhtTable return DHT info', () async {
      adapter.on('GET', '/dht/stats', (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'id': 'abcdef0123456789abcdef0123456789abcdef01',
            'outstanding_requests': 1,
            'routing_table_size': 50,
            'routing_table_size_v6': 12,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final dhtStats = await client.getDhtStats();
      expect(dhtStats.routingTableSize, 50);

      adapter.on('GET', '/dht/table', (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'v4': {'id': 'v4id', 'size': 50, 'buckets': {}},
            'v6': {'id': 'v6id', 'size': 12, 'buckets': {}},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final tables = await client.getDhtTable();
      expect(tables.v4.size, 50);
      expect(tables.v6.size, 12);
    });

    test(
      'forgetTorrent, addPeers, and getPeerStats operate on torrent lifecycle',
      () async {
        bool forgetCalled = false;
        adapter.on('POST', '/torrents/1/forget', (options) {
          forgetCalled = true;
          return ResponseBody.fromString('{}', 200);
        });
        await client.forgetTorrent(1);
        expect(forgetCalled, true);

        String? addedPeersBody;
        adapter.on('POST', '/torrents/1/add_peers', (options) {
          addedPeersBody = options.data.toString();
          return ResponseBody.fromString(
            jsonEncode({'added': 2}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
        final count = await client.addPeers(1, [
          '1.1.1.1:6881',
          '2.2.2.2:6881',
        ]);
        expect(count, 2);
        expect(addedPeersBody, '1.1.1.1:6881\n2.2.2.2:6881');

        adapter.on('GET', '/torrents/1/peer_stats', (options) {
          return ResponseBody.fromString(
            jsonEncode({
              'peers': {
                '1.1.1.1:6881': {
                  'counters': {
                    'incoming_connections': 0,
                    'fetched_bytes': 100,
                    'uploaded_bytes': 50,
                    'total_time_connecting_ms': 20,
                    'connection_attempts': 1,
                    'connections': 1,
                    'errors': 0,
                    'fetched_chunks': 1,
                    'downloaded_and_checked_pieces': 0,
                    'total_piece_download_ms': 50,
                    'times_stolen_from_me': 0,
                    'times_i_stole': 0,
                  },
                  'state': 'live',
                  'conn_kind': 'tcp',
                  'client_name': 'Transmission/3.00',
                },
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
        final peerStats = await client.getPeerStats(1);
        expect(peerStats.peers.containsKey('1.1.1.1:6881'), true);
        expect(
          peerStats.peers['1.1.1.1:6881']?.clientName,
          'Transmission/3.00',
        );
      },
    );

    test(
      'getTorrentMetadata and getTorrentHaves return binary or SVG payloads',
      () async {
        adapter.on('GET', '/torrents/1/metadata', (options) {
          return ResponseBody.fromBytes(
            [0x64, 0x38, 0x3a], // 'd8:'
            200,
            headers: {
              Headers.contentTypeHeader: ['application/x-bittorrent'],
            },
          );
        });
        final meta = await client.getTorrentMetadata(1);
        expect(meta, [0x64, 0x38, 0x3a]);

        adapter.on('GET', '/torrents/1/haves', (options) {
          final accept = options.headers['Accept']?.toString() ?? '';
          if (accept.contains('application/octet-stream')) {
            return ResponseBody.fromBytes([0xFF, 0x00], 200);
          }
          return ResponseBody.fromString('<svg></svg>', 200);
        });

        final havesBytes = await client.getTorrentHavesBytes(1);
        expect(havesBytes, [0xFF, 0x00]);

        final havesSvg = await client.getTorrentHavesSvg(1);
        expect(havesSvg, '<svg></svg>');
      },
    );

    test('playlists, resolveMagnet, and createTorrent succeed', () async {
      expect(
        client.getGlobalPlaylistUrl(),
        'http://127.0.0.1:4242/torrents/playlist',
      );
      expect(
        client.getTorrentPlaylistUrl(5),
        'http://127.0.0.1:4242/torrents/5/playlist',
      );

      adapter.on('GET', '/torrents/playlist', (options) {
        return ResponseBody.fromString('#EXTM3U\n#EXTINF:demo.mp4', 200);
      });
      final globalM3u = await client.getGlobalPlaylist();
      expect(globalM3u.startsWith('#EXTM3U'), true);

      adapter.on('GET', '/torrents/5/playlist', (options) {
        return ResponseBody.fromString('#EXTM3U\n#EXTINF:stream.mp4', 200);
      });
      final itemM3u = await client.getTorrentPlaylist(5);
      expect(itemM3u.contains('stream.mp4'), true);

      adapter.on('POST', '/torrents/resolve_magnet', (options) {
        return ResponseBody.fromBytes([1, 2, 3], 200);
      });
      final magnetBytes = await client.resolveMagnet('magnet:?xt=urn:btih:xyz');
      expect(magnetBytes, [1, 2, 3]);

      adapter.on('POST', '/torrents/create', (options) {
        final output = options.queryParameters['output'];
        if (output == 'torrent') {
          return ResponseBody.fromBytes([9, 8, 7], 200);
        }
        return ResponseBody.fromString('magnet:?xt=urn:btih:created', 200);
      });

      final magnetRes = await client.createTorrent('/downloads/my_folder');
      expect(magnetRes, 'magnet:?xt=urn:btih:created');

      final torrentBytesRes = await client.createTorrent(
        '/downloads/my_folder',
        output: 'torrent',
      );
      expect(torrentBytesRes, [9, 8, 7]);
    });
  });
}
