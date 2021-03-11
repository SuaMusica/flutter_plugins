import '_map.dart';
import 'dart:core';

class Playlist {
  Playlist({
    required this.id,
    required this.name,
    this.coverUrl,
    this.shareUrl,
    required this.artistName,
    required this.artistId,
    this.isVerified,
    this.createdAt,
  }) : super();

  final int id;
  final String name;
  final String? coverUrl;
  final String? shareUrl;
  final String artistName;
  final int artistId;
  final bool? isVerified;
  final DateTime? createdAt;

  factory Playlist.fromJson(Map<dynamic, dynamic> json) => Playlist(
        id: json.parseToInt('id') ?? -1,
        name: json['name'],
        coverUrl: json['cover_url'] ?? "",
        artistName: json['artist_name'],
        artistId: json.parseToInt('artist_id') ?? -1,
        shareUrl: json['share_url'] ?? "",
        isVerified: json['is_verified'] ?? false,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                json.parseToInt('created_at')!,
              ),
      );

  Map<String, dynamic> toJson() => {
        'id': this.id,
        'title': this.name,
        'cover': this.coverUrl,
        'shareurl': this.shareUrl,
        'username': this.artistName,
        'dono': this.artistId,
        'isverified': this.isVerified ?? false ? 1 : 0,
        'created_at': this.createdAt?.toIso8601String(),
      };
}
