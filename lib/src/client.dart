import 'dart:convert';

import 'package:dio/dio.dart';

import '../models.dart';

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
}
