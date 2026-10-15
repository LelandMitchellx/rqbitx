import 'speed.dart';

/// 1:1 Rust mapping for SessionCountersSnapshot.
class SessionCounters {
  final int fetchedBytes;
  final int uploadedBytes;
  final int blockedIncoming;
  final int blockedOutgoing;

  const SessionCounters({
    required this.fetchedBytes,
    required this.uploadedBytes,
    required this.blockedIncoming,
    required this.blockedOutgoing,
  });

  factory SessionCounters.fromJson(Map<String, dynamic> json) {
    return SessionCounters(
      fetchedBytes: (json['fetched_bytes'] as num?)?.toInt() ?? 0,
      uploadedBytes: (json['uploaded_bytes'] as num?)?.toInt() ?? 0,
      blockedIncoming: (json['blocked_incoming'] as num?)?.toInt() ?? 0,
      blockedOutgoing: (json['blocked_outgoing'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'fetched_bytes': fetchedBytes,
        'uploaded_bytes': uploadedBytes,
        'blocked_incoming': blockedIncoming,
        'blocked_outgoing': blockedOutgoing,
      };
}

/// 1:1 Rust mapping for AggregatePeerStats.
class AggregatePeerStats {
  final int queued;
  final int connecting;
  final int live;
  final int liveTcp;
  final int liveUtp;
  final int liveSocks;
  final int seen;
  final int dead;
  final int notNeeded;
  final int steals;

  const AggregatePeerStats({
    required this.queued,
    required this.connecting,
    required this.live,
    required this.liveTcp,
    required this.liveUtp,
    required this.liveSocks,
    required this.seen,
    required this.dead,
    required this.notNeeded,
    required this.steals,
  });

  factory AggregatePeerStats.fromJson(Map<String, dynamic> json) {
    return AggregatePeerStats(
      queued: (json['queued'] as num?)?.toInt() ?? 0,
      connecting: (json['connecting'] as num?)?.toInt() ?? 0,
      live: (json['live'] as num?)?.toInt() ?? 0,
      liveTcp: (json['live_tcp'] as num?)?.toInt() ?? 0,
      liveUtp: (json['live_utp'] as num?)?.toInt() ?? 0,
      liveSocks: (json['live_socks'] as num?)?.toInt() ?? 0,
      seen: (json['seen'] as num?)?.toInt() ?? 0,
      dead: (json['dead'] as num?)?.toInt() ?? 0,
      notNeeded: (json['not_needed'] as num?)?.toInt() ?? 0,
      steals: (json['steals'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'queued': queued,
        'connecting': connecting,
        'live': live,
        'live_tcp': liveTcp,
        'live_utp': liveUtp,
        'live_socks': liveSocks,
        'seen': seen,
        'dead': dead,
        'not_needed': notNeeded,
        'steals': steals,
      };
}

/// 1:1 Rust mapping for SingleStatSnapshot.
class SingleStatSnapshot {
  final int attempts;
  final int successes;
  final int errors;

  const SingleStatSnapshot({
    required this.attempts,
    required this.successes,
    required this.errors,
  });

  factory SingleStatSnapshot.fromJson(Map<String, dynamic> json) {
    return SingleStatSnapshot(
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      successes: (json['successes'] as num?)?.toInt() ?? 0,
      errors: (json['errors'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'attempts': attempts,
        'successes': successes,
        'errors': errors,
      };
}

/// 1:1 Rust mapping for PerFamilySnapshot (v4 / v6).
class PerFamilySnapshot {
  final SingleStatSnapshot v4;
  final SingleStatSnapshot v6;

  const PerFamilySnapshot({
    required this.v4,
    required this.v6,
  });

  factory PerFamilySnapshot.fromJson(Map<String, dynamic> json) {
    return PerFamilySnapshot(
      v4: SingleStatSnapshot.fromJson(
        (json['v4'] as Map<String, dynamic>?) ?? {},
      ),
      v6: SingleStatSnapshot.fromJson(
        (json['v6'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'v4': v4.toJson(),
        'v6': v6.toJson(),
      };
}

/// 1:1 Rust mapping for ConnectStatsSnapshot.
class ConnectStatsSnapshot {
  final PerFamilySnapshot socks;
  final PerFamilySnapshot tcp;
  final PerFamilySnapshot utp;

  const ConnectStatsSnapshot({
    required this.socks,
    required this.tcp,
    required this.utp,
  });

  factory ConnectStatsSnapshot.fromJson(Map<String, dynamic> json) {
    return ConnectStatsSnapshot(
      socks: PerFamilySnapshot.fromJson(
        (json['socks'] as Map<String, dynamic>?) ?? {},
      ),
      tcp: PerFamilySnapshot.fromJson(
        (json['tcp'] as Map<String, dynamic>?) ?? {},
      ),
      utp: PerFamilySnapshot.fromJson(
        (json['utp'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'socks': socks.toJson(),
        'tcp': tcp.toJson(),
        'utp': utp.toJson(),
      };
}

/// 1:1 Rust mapping for librqbit SessionStatsSnapshot.
class SessionStatsSnapshot {
  final SessionCounters counters;
  final Speed downloadSpeed;
  final Speed uploadSpeed;
  final AggregatePeerStats peers;
  final int uptimeSeconds;
  final ConnectStatsSnapshot connections;

  const SessionStatsSnapshot({
    required this.counters,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.peers,
    required this.uptimeSeconds,
    required this.connections,
  });

  factory SessionStatsSnapshot.fromJson(Map<String, dynamic> json) {
    return SessionStatsSnapshot(
      counters: SessionCounters.fromJson(
        (json['counters'] as Map<String, dynamic>?) ?? {},
      ),
      downloadSpeed: Speed.fromJson(
        (json['download_speed'] as Map<String, dynamic>?) ?? {},
      ),
      uploadSpeed: Speed.fromJson(
        (json['upload_speed'] as Map<String, dynamic>?) ?? {},
      ),
      peers: AggregatePeerStats.fromJson(
        (json['peers'] as Map<String, dynamic>?) ?? {},
      ),
      uptimeSeconds: (json['uptime_seconds'] as num?)?.toInt() ?? 0,
      connections: ConnectStatsSnapshot.fromJson(
        (json['connections'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'counters': counters.toJson(),
        'download_speed': downloadSpeed.toJson(),
        'upload_speed': uploadSpeed.toJson(),
        'peers': peers.toJson(),
        'uptime_seconds': uptimeSeconds,
        'connections': connections.toJson(),
      };
}
