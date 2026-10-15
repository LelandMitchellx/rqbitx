/// Torrent file details from librqbit.
/// Direct 1:1 mapping of librqbit `TorrentDetailsResponseFile`.
class TorrentFile {
  final String name;
  final List<String> components;
  final int length;
  final bool included;
  final Map<String, dynamic> attributes;

  const TorrentFile({
    required this.name,
    required this.components,
    required this.length,
    required this.included,
    this.attributes = const {},
  });

  factory TorrentFile.fromJson(Map<String, dynamic> json) {
    return TorrentFile(
      name: json['name'] as String? ?? '',
      components:
          (json['components'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      length: (json['length'] as num?)?.toInt() ?? 0,
      included: json['included'] as bool? ?? true,
      attributes: json['attributes'] != null
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'components': components,
    'length': length,
    'included': included,
    'attributes': attributes,
  };
}
