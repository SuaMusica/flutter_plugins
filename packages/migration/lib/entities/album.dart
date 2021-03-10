import 'dart:core';

import '_map.dart';

class Album {
  Album({
    required this.id,
    this.name,
    this.coverUrl,
    this.artistName,
    this.artistId,
    this.shareUrl,
    required this.isVerified,
    this.createdAt,
  }) : super();

  final int id;
  final String? name;
  final String? coverUrl;
  final String? artistName;
  final int? artistId;
  final String? shareUrl;
  final bool? isVerified;
  final DateTime? createdAt;

  factory Album.fromJson(Map<dynamic, dynamic> json) => Album(
      id: json.parseToInt('id') ?? -1,
      name: json['name'] as String?,
      coverUrl: json['cover_url'] as String?,
      artistName: json['artist_name'] as String?,
      artistId: json.parseToInt('artist_id') ?? -1,
      shareUrl: json['share_url'] as String?,
      isVerified: json['is_verified'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              json.parseToInt('created_at')!));

  Map<String, dynamic> toJson() => {
        'id': this.id,
        'title': this.name,
        'cover': this.coverUrl,
        'username': this.artistName,
        'dono': this.artistId,
        'shareurl': this.shareUrl,
        'vip': this.isVerified ?? false ? 1 : 0,
        'data_envio': this.createdAt?.toIso8601String(),
      };
}
