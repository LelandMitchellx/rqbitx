import 'torrent_file.dart';
import 'torrent_stats.dart';

/// Full details of a torrent task.
/// Direct 1:1 mapping of librqbit `TorrentDetailsResponse`.
class TorrentDetails {
  final int? id;
  final String infoHash;
  final String? name;
  final String outputFolder;
  final int totalPieces;
  final List<TorrentFile>? files;
  final TorrentStats? stats;

  const TorrentDetails({
    this.id,
    required this.infoHash,
    this.name,
    required this.outputFolder,
    required this.totalPieces,
    this.files,
    this.stats,
  });

  factory TorrentDetails.fromJson(Map<String, dynamic> json) {
    return TorrentDetails(
      id: (json['id'] as num?)?.toInt(),
      infoHash: json['info_hash'] as String? ?? '',
      name: json['name'] as String?,
      outputFolder: json['output_folder'] as String? ?? '',
      totalPieces: (json['total_pieces'] as num?)?.toInt() ?? 0,
      files: (json['files'] as List<dynamic>?)
          ?.map(
            (e) => TorrentFile.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      stats: json['stats'] != null
          ? TorrentStats.fromJson(
              Map<String, dynamic>.from(json['stats'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'info_hash': infoHash,
    if (name != null) 'name': name,
    'output_folder': outputFolder,
    'total_pieces': totalPieces,
    if (files != null) 'files': files!.map((f) => f.toJson()).toList(),
    if (stats != null) 'stats': stats!.toJson(),
  };
}
