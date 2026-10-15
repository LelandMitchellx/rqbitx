/// 1:1 Rust mapping for librqbit API root metadata.
class ServerInfo {
  final String server;
  final String version;
  final Map<String, String> apis;

  const ServerInfo({
    required this.server,
    required this.version,
    required this.apis,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    final apisRaw = json['apis'] as Map<String, dynamic>? ?? {};
    return ServerInfo(
      server: json['server'] as String? ?? '',
      version: json['version'] as String? ?? '',
      apis: apisRaw.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, dynamic> toJson() => {
        'server': server,
        'version': version,
        'apis': apis,
      };
}
