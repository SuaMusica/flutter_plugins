import 'dart:convert';

import 'album.dart';
import 'playlist.dart';
import 'media.dart';

class AndroidDownloadedContent {
  AndroidDownloadedContent({
    this.albums,
    this.playlists,
    this.medias,
  });
  final List<Album> albums;
  final List<Playlist> playlists;
  final List<Media> medias;

  factory AndroidDownloadedContent.fromJson(Map<dynamic, dynamic> json) =>
      AndroidDownloadedContent(
        albums: (json['albums'] as List<dynamic>)
            .where((item) => item is Map<dynamic, dynamic>)
            .map((item) => Album.fromJson(item as Map<dynamic, dynamic>),
        ).toList(),
        playlists: (json['playlists'] as List<dynamic>)
            .where((item) => item is Map<dynamic, dynamic>)
            .map((item) => Playlist.fromJson(item as Map<dynamic, dynamic>),
        ).toList(),
        medias: (json['medias'] as List<dynamic>)
            .where((item) => item is Map<dynamic, dynamic>)
            .map((item) => Media.fromJson(item as Map<dynamic, dynamic>),
        ).toList(),
      );

  Map<String, dynamic> toJson() =>
      {
        'albums': jsonEncode(this.albums),
        'playlists': jsonEncode(this.playlists),
        'medias': jsonEncode(this.medias),
      };
}