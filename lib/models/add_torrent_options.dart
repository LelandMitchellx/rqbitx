/// Query parameters for adding a torrent.
/// Direct 1:1 mapping of librqbit `TorrentAddQueryParams`.
class AddTorrentOptions {
  final bool? overwrite;
  final String? outputFolder;
  final String? subFolder;
  final List<int>? onlyFiles;
  final bool? isUrl;
  final bool? listOnly;

  const AddTorrentOptions({
    this.overwrite,
    this.outputFolder,
    this.subFolder,
    this.onlyFiles,
    this.isUrl,
    this.listOnly,
  });

  /// Converts non-null fields to URL query parameter map.
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (overwrite != null) params['overwrite'] = overwrite.toString();
    if (outputFolder != null) params['output_folder'] = outputFolder!;
    if (subFolder != null) params['sub_folder'] = subFolder!;
    if (onlyFiles != null) params['only_files'] = onlyFiles!.join(',');
    if (isUrl != null) params['is_url'] = isUrl.toString();
    if (listOnly != null) params['list_only'] = listOnly.toString();
    return params;
  }
}
