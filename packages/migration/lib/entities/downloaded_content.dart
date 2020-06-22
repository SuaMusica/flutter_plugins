class DownloadedContent {
  DownloadedContent({
    this.id,
    this.path,
  });
  final String id;
  final String path;

  factory DownloadedContent.fromJson(Map<dynamic, dynamic> json) =>
      DownloadedContent(id: json['id'] as String, path: json['path'] as String);

  Map<String, dynamic> toJson() => {'id': this.id, 'path': this.path};
}