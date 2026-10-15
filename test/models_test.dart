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
          },
        ],
        'stats': {
          'state': 'paused',
          'file_progress': [0],
          'progress_bytes': 0,
          'uploaded_bytes': 0,
          'total_bytes': 50000000,
          'finished': false,
        },
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
      expect(
        addResp.details.infoHash,
        'feedbeef00112233445566778899aabbccddeeff',
      );
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
          },
        ],
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

    test('ServerInfo deserializes correctly', () {
      final json = {
        'server': 'rqbit',
        'version': '9.0.1',
        'apis': {'GET /': 'list apis', 'GET /stats': 'session stats'},
      };
      final info = ServerInfo.fromJson(json);
      expect(info.server, 'rqbit');
      expect(info.version, '9.0.1');
      expect(info.apis['GET /'], 'list apis');
      expect(info.toJson(), json);
    });

    test('LimitsConfig deserializes correctly', () {
      final json = {'upload_bps': 1048576, 'download_bps': 5242880};
      final limits = LimitsConfig.fromJson(json);
      expect(limits.uploadBps, 1048576);
      expect(limits.downloadBps, 5242880);
      expect(limits.toJson(), json);
    });

    test('SessionStatsSnapshot deserializes correctly', () {
      final json = {
        'counters': {
          'fetched_bytes': 1000,
          'uploaded_bytes': 2000,
          'blocked_incoming': 10,
          'blocked_outgoing': 20,
        },
        'download_speed': {'mbps': 1.5, 'human_readable': '1.50 MiB/s'},
        'upload_speed': {'mbps': 0.5, 'human_readable': '500 KiB/s'},
        'peers': {
          'queued': 1,
          'connecting': 2,
          'live': 3,
          'live_tcp': 3,
          'live_utp': 0,
          'live_socks': 0,
          'seen': 10,
          'dead': 5,
          'not_needed': 0,
          'steals': 0,
        },
        'uptime_seconds': 120,
        'connections': {
          'socks': {
            'v4': {'attempts': 0, 'successes': 0, 'errors': 0},
            'v6': {'attempts': 0, 'successes': 0, 'errors': 0},
          },
          'tcp': {
            'v4': {'attempts': 5, 'successes': 3, 'errors': 2},
            'v6': {'attempts': 0, 'successes': 0, 'errors': 0},
          },
          'utp': {
            'v4': {'attempts': 0, 'successes': 0, 'errors': 0},
            'v6': {'attempts': 0, 'successes': 0, 'errors': 0},
          },
        },
      };
      final stats = SessionStatsSnapshot.fromJson(json);
      expect(stats.uptimeSeconds, 120);
      expect(stats.counters.fetchedBytes, 1000);
      expect(stats.downloadSpeed.mbps, 1.5);
      expect(stats.peers.liveTcp, 3);
      expect(stats.connections.tcp.v4.attempts, 5);
      expect(stats.toJson(), json);
    });

    test('DhtStats and RoutingTable deserialize correctly', () {
      final statsJson = {
        'id': '0123456789abcdef0123456789abcdef01234567',
        'outstanding_requests': 2,
        'routing_table_size': 42,
        'routing_table_size_v6': 10,
      };
      final dht = DhtStats.fromJson(statsJson);
      expect(dht.id, '0123456789abcdef0123456789abcdef01234567');
      expect(dht.routingTableSize, 42);
      expect(dht.toJson(), statsJson);

      final tableJson = {
        'v4': {
          'id': 'abc',
          'size': 5,
          'buckets': {'data': []},
        },
        'v6': {
          'id': 'def',
          'size': 2,
          'buckets': {'data': []},
        },
      };
      final tables = DhtRoutingTableResponse.fromJson(tableJson);
      expect(tables.v4.size, 5);
      expect(tables.v6.id, 'def');
      expect(tables.toJson(), tableJson);
    });

    test('PeerStatsSnapshot deserializes correctly', () {
      final json = {
        'peers': {
          '1.2.3.4:6881': {
            'counters': {
              'incoming_connections': 1,
              'fetched_bytes': 500,
              'uploaded_bytes': 200,
              'total_time_connecting_ms': 50,
              'connection_attempts': 1,
              'connections': 1,
              'errors': 0,
              'fetched_chunks': 5,
              'downloaded_and_checked_pieces': 1,
              'total_piece_download_ms': 100,
              'times_stolen_from_me': 0,
              'times_i_stole': 0,
            },
            'state': 'live',
            'conn_kind': 'tcp',
            'client_name': 'qBittorrent/4.5.0',
          },
        },
      };
      final snapshot = PeerStatsSnapshot.fromJson(json);
      expect(snapshot.peers.containsKey('1.2.3.4:6881'), true);
      final p = snapshot.peers['1.2.3.4:6881']!;
      expect(p.state, 'live');
      expect(p.clientName, 'qBittorrent/4.5.0');
      expect(p.counters.fetchedBytes, 500);
      expect(snapshot.toJson(), json);
    });
  });
}
