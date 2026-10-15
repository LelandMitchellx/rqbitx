import 'torrent_details.dart';

/// Response containing a list of all torrents in the session.
/// Direct 1:1 mapping of librqbit `TorrentListResponse`.
class TorrentListResponse {
  final List<TorrentDetails> torrents;

  const TorrentListResponse({required this.torrents});

  factory TorrentListResponse.fromJson(Map<String, dynamic> json) {
    return TorrentListResponse(
      torrents:
          (json['torrents'] as List<dynamic>?)
              ?.map(
                (e) => TorrentDetails.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'torrents': torrents.map((t) => t.toJson()).toList(),
  };
}
