import 'dart:core';

class Id3 {
  Id3({
    this.artist,
    this.album,
    required this.path,
  }) : super();

  final String? artist;
  final String? album;
  final String path;

  factory Id3.fromJson(Map<dynamic, dynamic> json) => Id3(
        artist: json['artist'] ?? "",
        album: json['album'] ?? "",
        path: json['path'] ?? "",
      );

  Map<String, dynamic> toJson() => {
        'artist': this.artist,
        'album': this.album,
        'path': this.path,
      };
}
