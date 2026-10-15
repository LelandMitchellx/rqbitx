/// 1:1 Rust mapping for librqbit LimitsConfig.
class LimitsConfig {
  final int? uploadBps;
  final int? downloadBps;

  const LimitsConfig({
    this.uploadBps,
    this.downloadBps,
  });

  factory LimitsConfig.fromJson(Map<String, dynamic> json) {
    return LimitsConfig(
      uploadBps: (json['upload_bps'] as num?)?.toInt(),
      downloadBps: (json['download_bps'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'upload_bps': uploadBps,
        'download_bps': downloadBps,
      };
}
