import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'models.dart';

/// Exception thrown by [RqbitClient] on network or HTTP protocol failure.
class RqbitClientException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic innerError;
  final Response? response;

  const RqbitClientException(
    this.message, {
    this.statusCode,
    this.innerError,
    this.response,
  });

  @override
  String toString() => 'RqbitClientException($statusCode): $message';
}

/// Official Dio-based HTTP client for the rqbit daemon REST API.
///
/// Encapsulates BaseUrl binding, timeout control, domain exception mapping,
/// and returns 1:1 Rust-derived strongly typed models.
class RqbitClient {
  final Dio dio;
  final String baseUrl;

  RqbitClient({
    required this.baseUrl,
    Dio? dio,
    Duration connectTimeout = const Duration(seconds: 5),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) : dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: connectTimeout,
               receiveTimeout: receiveTimeout,
             ),
           );

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String msg = e.message ?? 'HTTP request failed';
      if (data is Map && data.containsKey('error')) {
        msg = data['error'].toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      throw RqbitClientException(
        msg,
        statusCode: status,
        innerError: e,
        response: e.response,
      );
    } catch (e) {
      if (e is RqbitClientException) rethrow;
      throw RqbitClientException(e.toString(), innerError: e);
    }
  }

  /// Lists all torrents managed by the daemon session.
  /// Corresponds to `GET /torrents`.
  Future<TorrentListResponse> listTorrents() async {
    return _wrap(() async {
      final resp = await dio.get('/torrents');
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return TorrentListResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    });
  }

  /// Gets details of a specific torrent by its ID.
  /// Corresponds to `GET /torrents/{id}`.
  Future<TorrentDetails> getTorrentDetails(int id) async {
    return _wrap(() async {
      final resp = await dio.get('/torrents/$id');
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return TorrentDetails.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }

  /// Adds a new torrent from a magnet URL or link.
  /// Corresponds to `POST /torrents`.
  Future<AddTorrentResponse> addTorrent(
    String source, {
    AddTorrentOptions? options,
  }) async {
    return _wrap(() async {
      final queryParams = options?.toQueryParams() ?? {};
      final resp = await dio.post(
        '/torrents',
        data: source,
        queryParameters: queryParams,
        options: Options(contentType: 'text/plain'),
      );
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return AddTorrentResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    });
  }

  /// Permanently removes the torrent task and purges its downloaded files from disk.
  /// Corresponds to `POST /torrents/{id}/delete`.
  Future<void> deleteTorrent(int id) async {
    return _wrap(() async {
      await dio.post('/torrents/$id/delete');
    });
  }

  /// Pauses a torrent task.
  /// Corresponds to `POST /torrents/{id}/pause`.
  Future<void> pauseTorrent(int id) async {
    return _wrap(() async {
      await dio.post('/torrents/$id/pause');
    });
  }

  /// Resumes/starts a torrent task.
  /// Corresponds to `POST /torrents/{id}/start`.
  Future<void> startTorrent(int id) async {
    return _wrap(() async {
      await dio.post('/torrents/$id/start');
    });
  }

  /// Changes the selection of files to download for selective downloading (防爆盘流控).
  ///
  /// Passing an empty list `[]` means only torrent metadata is fetched without
  /// downloading any piece chunks to disk.
  /// Corresponds to `POST /torrents/{id}/update_only_files`.
  Future<void> updateOnlyFiles(int id, List<int> fileIndices) async {
    return _wrap(() async {
      await dio.post(
        '/torrents/$id/update_only_files',
        data: {'only_files': fileIndices},
      );
    });
  }

  /// Retrieves live statistics and instantaneous transfer speed.
  /// Corresponds to `GET /torrents/{id}/stats/v1`.
  Future<TorrentStats> getTorrentStats(int id) async {
    return _wrap(() async {
      final resp = await dio.get('/torrents/$id/stats/v1');
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return TorrentStats.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }

  /// Retrieves API root information and server version.
  /// Corresponds to `GET /`.
  Future<ServerInfo> getServerInfo() async {
    return _wrap(() async {
      final resp = await dio.get('/');
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return ServerInfo.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }

  /// Retrieves global session statistics across all torrents.
  /// Corresponds to `GET /stats`.
  Future<SessionStatsSnapshot> getSessionStats() async {
    return _wrap(() async {
      final resp = await dio.get('/stats');
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return SessionStatsSnapshot.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    });
  }

  /// Retrieves session rate limits for upload and download bandwidth.
  /// Corresponds to `GET /torrents/limits`.
  Future<LimitsConfig> getLimits() async {
    return _wrap(() async {
      final resp = await dio.get('/torrents/limits');
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return LimitsConfig.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }

  /// Updates session rate limits dynamically.
  /// Corresponds to `POST /torrents/limits`.
  Future<void> updateLimits(LimitsConfig limits) async {
    return _wrap(() async {
      await dio.post('/torrents/limits', data: limits.toJson());
    });
  }

  /// Dynamically updates the runtime log filter (e.g. "debug", "info").
  /// Corresponds to `POST /rust_log`.
  Future<void> setRustLog(String rustLog) async {
    return _wrap(() async {
      await dio.post(
        '/rust_log',
        data: rustLog,
        options: Options(contentType: 'text/plain'),
      );
    });
  }

  /// Retrieves DHT node statistics.
  /// Corresponds to `GET /dht/stats`.
  Future<DhtStats> getDhtStats() async {
    return _wrap(() async {
      final resp = await dio.get('/dht/stats');
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return DhtStats.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }

  /// Retrieves IPv4 and IPv6 DHT routing tables.
  /// Corresponds to `GET /dht/table`.
  Future<DhtRoutingTableResponse> getDhtTable() async {
    return _wrap(() async {
      final resp = await dio.get('/dht/table');
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return DhtRoutingTableResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    });
  }

  /// Removes a torrent from the session while preserving downloaded files on disk.
  /// Corresponds to `POST /torrents/{id}/forget`.
  Future<void> forgetTorrent(int id) async {
    return _wrap(() async {
      await dio.post('/torrents/$id/forget');
    });
  }

  /// Adds extra peer socket addresses to an active torrent session.
  /// Corresponds to `POST /torrents/{id}/add_peers`.
  Future<int> addPeers(int id, List<String> peers) async {
    return _wrap(() async {
      final resp = await dio.post(
        '/torrents/$id/add_peers',
        data: peers.join('\n'),
        options: Options(contentType: 'text/plain'),
      );
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return (data['added'] as num?)?.toInt() ?? 0;
    });
  }

  /// Retrieves per-peer statistics for an active torrent.
  /// Corresponds to `GET /torrents/{id}/peer_stats`.
  Future<PeerStatsSnapshot> getPeerStats(
    int id, {
    String state = 'live',
  }) async {
    return _wrap(() async {
      final resp = await dio.get(
        '/torrents/$id/peer_stats',
        queryParameters: {'state': state},
      );
      final data = resp.data is String
          ? jsonDecode(resp.data as String)
          : resp.data;
      return PeerStatsSnapshot.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }

  /// Downloads the raw .torrent metadata file for a managed torrent.
  /// Corresponds to `GET /torrents/{id}/metadata`.
  Future<Uint8List> getTorrentMetadata(int id) async {
    return _wrap(() async {
      final resp = await dio.get<List<int>>(
        '/torrents/$id/metadata',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data ?? []);
    });
  }

  /// Retrieves the bitfield of completed pieces as raw bytes.
  /// Corresponds to `GET /torrents/{id}/haves` with binary Accept header.
  Future<Uint8List> getTorrentHavesBytes(int id) async {
    return _wrap(() async {
      final resp = await dio.get<List<int>>(
        '/torrents/$id/haves',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/octet-stream'},
        ),
      );
      return Uint8List.fromList(resp.data ?? []);
    });
  }

  /// Retrieves the piece completion visualization as an SVG string.
  /// Corresponds to `GET /torrents/{id}/haves`.
  Future<String> getTorrentHavesSvg(int id) async {
    return _wrap(() async {
      final resp = await dio.get<String>(
        '/torrents/$id/haves',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'image/svg+xml'},
        ),
      );
      return resp.data ?? '';
    });
  }

  /// Returns the streaming URL for the global M3U8 playlist across all torrents.
  String getGlobalPlaylistUrl() {
    return Uri.parse(baseUrl).resolve('/torrents/playlist').toString();
  }

  /// Retrieves the global M3U8 playlist content.
  /// Corresponds to `GET /torrents/playlist`.
  Future<String> getGlobalPlaylist() async {
    return _wrap(() async {
      final resp = await dio.get<String>(
        '/torrents/playlist',
        options: Options(responseType: ResponseType.plain),
      );
      return resp.data ?? '';
    });
  }

  /// Returns the streaming URL for a specific torrent's M3U8 playlist.
  String getTorrentPlaylistUrl(int id) {
    return Uri.parse(baseUrl).resolve('/torrents/$id/playlist').toString();
  }

  /// Retrieves the M3U8 playlist content for a specific torrent.
  /// Corresponds to `GET /torrents/{id}/playlist`.
  Future<String> getTorrentPlaylist(int id) async {
    return _wrap(() async {
      final resp = await dio.get<String>(
        '/torrents/$id/playlist',
        options: Options(responseType: ResponseType.plain),
      );
      return resp.data ?? '';
    });
  }

  /// Resolves a magnet URL into raw .torrent file bytes without keeping it in the session.
  /// Corresponds to `POST /torrents/resolve_magnet`.
  Future<Uint8List> resolveMagnet(String magnetUri) async {
    return _wrap(() async {
      final resp = await dio.post<List<int>>(
        '/torrents/resolve_magnet',
        data: magnetUri,
        options: Options(
          contentType: 'text/plain',
          responseType: ResponseType.bytes,
        ),
      );
      return Uint8List.fromList(resp.data ?? []);
    });
  }

  /// Creates a torrent from a local folder and seeds it.
  /// Corresponds to `POST /torrents/create`.
  Future<dynamic> createTorrent(
    String folderPath, {
    String output = 'magnet',
    List<String>? trackers,
    String? name,
  }) async {
    return _wrap(() async {
      final queryParams = <String, dynamic>{
        'output': output,
        if (trackers != null && trackers.isNotEmpty) 'trackers': trackers,
        'name': ?name,
      };
      final resp = await dio.post(
        '/torrents/create',
        data: folderPath,
        queryParameters: queryParams,
        options: Options(
          contentType: 'text/plain',
          responseType: output == 'torrent'
              ? ResponseType.bytes
              : ResponseType.plain,
        ),
      );
      if (output == 'torrent') {
        return Uint8List.fromList((resp.data as List<int>?) ?? []);
      }
      return resp.data.toString();
    });
  }
}
