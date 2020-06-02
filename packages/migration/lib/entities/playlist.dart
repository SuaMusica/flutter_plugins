import '_map.dart';
import 'dart:core';

class Playlist {
  Playlist(
      {this.id,
      this.name,
      this.coverUrl,
      this.shareUrl,
      this.artistName,
      this.artistId,
      this.isVerified,
      this.createdAt})
      : super();

  final int id;
  final String name;
  final String coverUrl;
  final String shareUrl;
  final String artistName;
  final int artistId;
  final bool isVerified;
  final DateTime createdAt;

  factory Playlist.fromJson(Map<dynamic, dynamic> json) => Playlist(
      id: json.parseToInt('id'),
      name: json['name'] as String,
      coverUrl: json['cover_url'] as String,
      artistName: json['artist_name'] as String,
      artistId: json.parseToInt('artist_id'),
      shareUrl: json['share_url'] as String,
      isVerified: json['is_verified'] as bool,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json.parseToInt('created_at')));

  Map<String, dynamic> toJson() => {
        'id': this.id,
        'title': this.name,
        'cover': this.coverUrl,
        'shareurl': this.shareUrl,
        'username': this.artistName,
        'dono': this.artistId,
        'isverified': this.isVerified ? 1 : 0,
        'created_at': this.createdAt?.toIso8601String(),
      };
}
