/// 1:1 Rust mapping for librqbit PeerCounters.
class PeerCounters {
  final int incomingConnections;
  final int fetchedBytes;
  final int uploadedBytes;
  final int totalTimeConnectingMs;
  final int connectionAttempts;
  final int connections;
  final int errors;
  final int fetchedChunks;
  final int downloadedAndCheckedPieces;
  final int totalPieceDownloadMs;
  final int timesStolenFromMe;
  final int timesIStole;

  const PeerCounters({
    required this.incomingConnections,
    required this.fetchedBytes,
    required this.uploadedBytes,
    required this.totalTimeConnectingMs,
    required this.connectionAttempts,
    required this.connections,
    required this.errors,
    required this.fetchedChunks,
    required this.downloadedAndCheckedPieces,
    required this.totalPieceDownloadMs,
    required this.timesStolenFromMe,
    required this.timesIStole,
  });

  factory PeerCounters.fromJson(Map<String, dynamic> json) {
    return PeerCounters(
      incomingConnections:
          (json['incoming_connections'] as num?)?.toInt() ?? 0,
      fetchedBytes: (json['fetched_bytes'] as num?)?.toInt() ?? 0,
      uploadedBytes: (json['uploaded_bytes'] as num?)?.toInt() ?? 0,
      totalTimeConnectingMs:
          (json['total_time_connecting_ms'] as num?)?.toInt() ?? 0,
      connectionAttempts:
          (json['connection_attempts'] as num?)?.toInt() ?? 0,
      connections: (json['connections'] as num?)?.toInt() ?? 0,
      errors: (json['errors'] as num?)?.toInt() ?? 0,
      fetchedChunks: (json['fetched_chunks'] as num?)?.toInt() ?? 0,
      downloadedAndCheckedPieces:
          (json['downloaded_and_checked_pieces'] as num?)?.toInt() ?? 0,
      totalPieceDownloadMs:
          (json['total_piece_download_ms'] as num?)?.toInt() ?? 0,
      timesStolenFromMe: (json['times_stolen_from_me'] as num?)?.toInt() ?? 0,
      timesIStole: (json['times_i_stole'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'incoming_connections': incomingConnections,
        'fetched_bytes': fetchedBytes,
        'uploaded_bytes': uploadedBytes,
        'total_time_connecting_ms': totalTimeConnectingMs,
        'connection_attempts': connectionAttempts,
        'connections': connections,
        'errors': errors,
        'fetched_chunks': fetchedChunks,
        'downloaded_and_checked_pieces': downloadedAndCheckedPieces,
        'total_piece_download_ms': totalPieceDownloadMs,
        'times_stolen_from_me': timesStolenFromMe,
        'times_i_stole': timesIStole,
      };
}

/// 1:1 Rust mapping for librqbit PeerStats.
class PeerStats {
  final PeerCounters counters;
  final String state;
  final String? connKind;
  final String? clientName;

  const PeerStats({
    required this.counters,
    required this.state,
    this.connKind,
    this.clientName,
  });

  factory PeerStats.fromJson(Map<String, dynamic> json) {
    return PeerStats(
      counters: PeerCounters.fromJson(
        (json['counters'] as Map<String, dynamic>?) ?? {},
      ),
      state: json['state'] as String? ?? '',
      connKind: json['conn_kind'] as String?,
      clientName: json['client_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'counters': counters.toJson(),
        'state': state,
        'conn_kind': connKind,
        'client_name': clientName,
      };
}

/// 1:1 Rust mapping for PeerStatsSnapshot.
class PeerStatsSnapshot {
  final Map<String, PeerStats> peers;

  const PeerStatsSnapshot({required this.peers});

  factory PeerStatsSnapshot.fromJson(Map<String, dynamic> json) {
    final peersRaw = json['peers'] as Map<String, dynamic>? ?? {};
    return PeerStatsSnapshot(
      peers: peersRaw.map(
        (k, v) => MapEntry(
          k,
          PeerStats.fromJson((v as Map<String, dynamic>?) ?? {}),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'peers': peers.map((k, v) => MapEntry(k, v.toJson())),
      };
}
