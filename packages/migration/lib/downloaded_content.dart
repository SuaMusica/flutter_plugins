class DownloadedContent {
  DownloadedContent({
    this.id,
    this.path,
  });
  final int id;
  final String path;

  factory DownloadedContent.fromJson(Map<String, dynamic> json) =>
      DownloadedContent(id: json['id'] as int, path: json['path'] as String);

  Map<String, dynamic> toJson() => {'id': this.id, 'path': this.path};
}
