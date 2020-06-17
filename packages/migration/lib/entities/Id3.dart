import 'dart:core';

class Id3 {
  Id3({
    this.artist,
    this.album,
    this.path,
  }) : super();

  final String artist;
  final String album;
  final String path;

  factory Id3.fromJson(Map<dynamic, dynamic> json) => Id3(
        artist: json['artist'] as String,
        album: json['album'] as String,
        path: json['path'] as String,
      );

  Map<String, dynamic> toJson() => {
        'artist': this.artist,
        'album': this.album,
        'path': this.path,
      };
}
