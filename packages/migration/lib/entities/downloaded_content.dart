class DownloadedContent {
  DownloadedContent({
    required this.id,
    required this.path,
  });
  final String id;
  final String path;

  factory DownloadedContent.fromJson(Map<dynamic, dynamic> json) =>
      DownloadedContent(
        id: json['id'] as String,
        path: json['path'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': this.id,
        'path': this.path,
      };
}
