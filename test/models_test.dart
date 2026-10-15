import 'package:flutter_test/flutter_test.dart';
import 'package:rqbitx/models.dart';

void main() {
  group('librqbit 1:1 Dart Models Serialization', () {
    test('Speed deserializes correctly', () {
      final json = {'mbps': 2.5, 'human_readable': '2.50 MiB/s'};
      final speed = Speed.fromJson(json);
      expect(speed.mbps, 2.5);
      expect(speed.humanReadable, '2.50 MiB/s');
      expect(speed.toJson(), json);
    });

    test('TorrentFile deserializes correctly', () {
      final json = {
        'name': 'sample.mp4',
        'components': ['movies', 'sample.mp4'],
        'length': 104857600,
        'included': true,
        'attributes': {'padding': false},
      };
      final file = TorrentFile.fromJson(json);
      expect(file.name, 'sample.mp4');
      expect(file.components, ['movies', 'sample.mp4']);
      expect(file.length, 104857600);
      expect(file.included, isTrue);
      expect(file.attributes['padding'], isFalse);
    });

    test('StatsSnapshot and LiveStats deserialize correctly', () {
      final json = {
        'snapshot': {
          'downloaded_and_checked_bytes': 1024,
          'fetched_bytes': 2048,
          'uploaded_bytes': 512,
          'downloaded_and_checked_pieces': 10,
          'total_piece_download_ms': 500,
        },
        'download_speed': {'mbps': 1.2, 'human_readable': '1.20 MiB/s'},
        'upload_speed': {'mbps': 0.1, 'human_readable': '0.10 MiB/s'},
        'time_remaining': {'human_readable': '2m 30s'},
      };
      final live = TorrentLiveStats.fromJson(json);
      expect(live.snapshot.fetchedBytes, 2048);
      expect(live.downloadSpeed.mbps, 1.2);
      expect(live.uploadSpeed.humanReadable, '0.10 MiB/s');
      expect(live.timeRemainingHumanReadable, '2m 30s');
    });

    test('TorrentStats deserializes correctly with state and live data', () {
      final json = {
        'state': 'live',
        'file_progress': [10240, 20480],
        'error': null,
        'progress_bytes': 30720,
        'uploaded_bytes': 1024,
        'total_bytes': 1048576,
        'finished': false,
        'live': {
          'snapshot': {
            'downloaded_and_checked_bytes': 30720,
            'fetched_bytes': 30720,
            'uploaded_bytes': 1024,
            'downloaded_and_checked_pieces': 2,
            'total_piece_download_ms': 120,
          },
          'download_speed': {'mbps': 5.0, 'human_readable': '5.00 MiB/s'},
          'upload_speed': {'mbps': 0.0, 'human_readable': '0.00 MiB/s'},
        },
      };
      final stats = TorrentStats.fromJson(json);
      expect(stats.state, 'live');
      expect(stats.progressBytes, 30720);
      expect(stats.totalBytes, 1048576);
      expect(stats.finished, isFalse);
      expect(stats.live?.downloadSpeed.mbps, 5.0);
    });

    test('TorrentDetails deserializes with nested files and stats', () {
      final json = {
        'id': 1,
        'info_hash': '0123456789abcdef0123456789abcdef01234567',
        'name': 'BigBuckBunny',
        'output_folder': '/tmp/rqbit',
        'total_pieces': 120,
        'files': [
          {
            'name': 'bbb.mp4',
            'components': ['bbb.mp4'],
            'length': 50000000,
            'included': true,
            'attributes': {},
          }
        ],
        'stats': {
          'state': 'paused',
          'file_progress': [0],
          'progress_bytes': 0,
          'uploaded_bytes': 0,
          'total_bytes': 50000000,
          'finished': false,
        }
      };
      final details = TorrentDetails.fromJson(json);
      expect(details.id, 1);
      expect(details.infoHash, '0123456789abcdef0123456789abcdef01234567');
      expect(details.name, 'BigBuckBunny');
      expect(details.totalPieces, 120);
      expect(details.files?.length, 1);
      expect(details.files?.first.name, 'bbb.mp4');
      expect(details.stats?.state, 'paused');
    });

    test('ApiAddTorrentResponse deserializes correctly', () {
      final json = {
        'id': 2,
        'details': {
          'id': 2,
          'info_hash': 'feedbeef00112233445566778899aabbccddeeff',
          'output_folder': '/tmp/download',
          'total_pieces': 50,
        },
        'output_folder': '/tmp/download',
        'seen_peers': ['127.0.0.1:6881'],
      };
      final addResp = AddTorrentResponse.fromJson(json);
      expect(addResp.id, 2);
      expect(addResp.details.infoHash, 'feedbeef00112233445566778899aabbccddeeff');
      expect(addResp.outputFolder, '/tmp/download');
      expect(addResp.seenPeers, ['127.0.0.1:6881']);
    });

    test('TorrentListResponse deserializes a list of torrent details', () {
      final json = {
        'torrents': [
          {
            'id': 0,
            'info_hash': 'hash1',
            'output_folder': '/downloads',
            'total_pieces': 10,
          },
          {
            'id': 1,
            'info_hash': 'hash2',
            'output_folder': '/downloads',
            'total_pieces': 20,
          }
        ]
      };
      final list = TorrentListResponse.fromJson(json);
      expect(list.torrents.length, 2);
      expect(list.torrents[0].infoHash, 'hash1');
      expect(list.torrents[1].totalPieces, 20);
    });

    test('AddTorrentOptions serializes to query params map', () {
      const options = AddTorrentOptions(
        overwrite: true,
        outputFolder: '/custom/path',
        onlyFiles: [0, 2],
        isUrl: true,
        listOnly: false,
      );
      final queryParams = options.toQueryParams();
      expect(queryParams['overwrite'], 'true');
      expect(queryParams['output_folder'], '/custom/path');
      expect(queryParams['only_files'], '0,2');
      expect(queryParams['is_url'], 'true');
      expect(queryParams['list_only'], 'false');
    });
  });
}
