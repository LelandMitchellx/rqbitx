import 'speed.dart';

/// Instantaneous snapshot of peer and byte statistics.
/// Direct 1:1 mapping of librqbit `StatsSnapshot`.
class StatsSnapshot {
  final int downloadedAndCheckedBytes;
  final int fetchedBytes;
  final int uploadedBytes;
  final int downloadedAndCheckedPieces;
  final int totalPieceDownloadMs;

  const StatsSnapshot({
    this.downloadedAndCheckedBytes = 0,
    this.fetchedBytes = 0,
    this.uploadedBytes = 0,
    this.downloadedAndCheckedPieces = 0,
    this.totalPieceDownloadMs = 0,
  });

  factory StatsSnapshot.fromJson(Map<String, dynamic> json) {
    return StatsSnapshot(
      downloadedAndCheckedBytes:
          (json['downloaded_and_checked_bytes'] as num?)?.toInt() ?? 0,
      fetchedBytes: (json['fetched_bytes'] as num?)?.toInt() ?? 0,
      uploadedBytes: (json['uploaded_bytes'] as num?)?.toInt() ?? 0,
      downloadedAndCheckedPieces:
          (json['downloaded_and_checked_pieces'] as num?)?.toInt() ?? 0,
      totalPieceDownloadMs:
          (json['total_piece_download_ms'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'downloaded_and_checked_bytes': downloadedAndCheckedBytes,
    'fetched_bytes': fetchedBytes,
    'uploaded_bytes': uploadedBytes,
    'downloaded_and_checked_pieces': downloadedAndCheckedPieces,
    'total_piece_download_ms': totalPieceDownloadMs,
  };
}

/// Live streaming and transmission statistics.
/// Direct 1:1 mapping of librqbit `LiveStats`.
class TorrentLiveStats {
  final StatsSnapshot snapshot;
  final Speed downloadSpeed;
  final Speed uploadSpeed;
  final String? timeRemainingHumanReadable;

  const TorrentLiveStats({
    required this.snapshot,
    required this.downloadSpeed,
    required this.uploadSpeed,
    this.timeRemainingHumanReadable,
  });

  factory TorrentLiveStats.fromJson(Map<String, dynamic> json) {
    String? eta;
    final tr = json['time_remaining'];
    if (tr is Map<String, dynamic>) {
      eta = tr['human_readable'] as String?;
    } else if (tr is String) {
      eta = tr;
    }

    return TorrentLiveStats(
      snapshot: json['snapshot'] != null
          ? StatsSnapshot.fromJson(
              Map<String, dynamic>.from(json['snapshot'] as Map),
            )
          : const StatsSnapshot(),
      downloadSpeed: json['download_speed'] != null
          ? Speed.fromJson(
              Map<String, dynamic>.from(json['download_speed'] as Map),
            )
          : const Speed(mbps: 0.0, humanReadable: '0.00 MiB/s'),
      uploadSpeed: json['upload_speed'] != null
          ? Speed.fromJson(
              Map<String, dynamic>.from(json['upload_speed'] as Map),
            )
          : const Speed(mbps: 0.0, humanReadable: '0.00 MiB/s'),
      timeRemainingHumanReadable: eta,
    );
  }

  Map<String, dynamic> toJson() => {
    'snapshot': snapshot.toJson(),
    'download_speed': downloadSpeed.toJson(),
    'upload_speed': uploadSpeed.toJson(),
    if (timeRemainingHumanReadable != null)
      'time_remaining': {'human_readable': timeRemainingHumanReadable},
  };
}

/// Complete torrent runtime statistics.
/// Direct 1:1 mapping of librqbit `TorrentStats`.
class TorrentStats {
  final String state;
  final bool? initializingPaused;
  final List<int> fileProgress;
  final String? error;
  final int progressBytes;
  final int uploadedBytes;
  final int totalBytes;
  final bool finished;
  final TorrentLiveStats? live;

  const TorrentStats({
    required this.state,
    this.initializingPaused,
    this.fileProgress = const [],
    this.error,
    this.progressBytes = 0,
    this.uploadedBytes = 0,
    this.totalBytes = 0,
    this.finished = false,
    this.live,
  });

  factory TorrentStats.fromJson(Map<String, dynamic> json) {
    return TorrentStats(
      state: json['state'] as String? ?? 'unknown',
      initializingPaused: json['initializing_paused'] as bool?,
      fileProgress:
          (json['file_progress'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      error: json['error'] as String?,
      progressBytes: (json['progress_bytes'] as num?)?.toInt() ?? 0,
      uploadedBytes: (json['uploaded_bytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['total_bytes'] as num?)?.toInt() ?? 0,
      finished: json['finished'] as bool? ?? false,
      live: json['live'] != null
          ? TorrentLiveStats.fromJson(
              Map<String, dynamic>.from(json['live'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'state': state,
    if (initializingPaused != null) 'initializing_paused': initializingPaused,
    'file_progress': fileProgress,
    if (error != null) 'error': error,
    'progress_bytes': progressBytes,
    'uploaded_bytes': uploadedBytes,
    'total_bytes': totalBytes,
    'finished': finished,
    if (live != null) 'live': live!.toJson(),
  };

  /// Helper to calculate progress fraction [0.0, 1.0].
  double get progressFraction {
    if (totalBytes <= 0) return 0.0;
    return (progressBytes / totalBytes).clamp(0.0, 1.0);
  }
}
