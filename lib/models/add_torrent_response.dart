import 'torrent_details.dart';

/// Response when a torrent is added.
/// Direct 1:1 mapping of librqbit `ApiAddTorrentResponse`.
class AddTorrentResponse {
  final int? id;
  final TorrentDetails details;
  final String outputFolder;
  final List<String>? seenPeers;

  const AddTorrentResponse({
    this.id,
    required this.details,
    required this.outputFolder,
    this.seenPeers,
  });

  factory AddTorrentResponse.fromJson(Map<String, dynamic> json) {
    return AddTorrentResponse(
      id: (json['id'] as num?)?.toInt(),
      details: TorrentDetails.fromJson(
        Map<String, dynamic>.from(json['details'] as Map),
      ),
      outputFolder: json['output_folder'] as String? ?? '',
      seenPeers: (json['seen_peers'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'details': details.toJson(),
    'output_folder': outputFolder,
    if (seenPeers != null) 'seen_peers': seenPeers,
  };
}
