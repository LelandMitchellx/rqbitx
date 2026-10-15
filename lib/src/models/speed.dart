/// Speed information from librqbit stats.
/// Direct 1:1 mapping of librqbit `Speed` struct.
class Speed {
  final double mbps;
  final String humanReadable;

  const Speed({
    required this.mbps,
    required this.humanReadable,
  });

  factory Speed.fromJson(Map<String, dynamic> json) {
    return Speed(
      mbps: (json['mbps'] as num?)?.toDouble() ?? 0.0,
      humanReadable: json['human_readable'] as String? ?? '0.00 MiB/s',
    );
  }

  Map<String, dynamic> toJson() => {
    'mbps': mbps,
    'human_readable': humanReadable,
  };

  @override
  String toString() => humanReadable;
}
