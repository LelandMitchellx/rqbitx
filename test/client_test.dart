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
  });
}
