import '_map.dart';

class Album {
  Album(
      {this.id,
        this.name,
        this.coverUrl,
        this.artistName,
        this.artistId,
        this.shareUrl,
        this.isVerified,
        this.createdAt})
      : super();


  final int id;
  final String name;
  final String coverUrl;
  final String artistName;
  final int artistId;
  final String shareUrl;
  final bool isVerified;
  final DateTime createdAt;

  factory Album.fromJson(Map<dynamic, dynamic> json) =>
      Album(
          id: json.parseToInt('id'),
          name: json['name'] as String,
          coverUrl: json['cover_url'] as String,
          artistName: json['artist_name'] as String,
          artistId: json.parseToInt('artist_id'),
          shareUrl: json['share_url'] as String,
          isVerified: json['is_verified'] as bool,
          createdAt: json['created_at'] == null ? null :
            DateTime.fromMillisecondsSinceEpoch(
                json.parseToInt('created_at')
            )
      );

  Map<String, dynamic> toJson() =>
      {
        'id': this.id,
        'name': this.name,
        'cover_url': this.coverUrl,
        'artist_name': this.artistName,
        'artist_id': this.artistId,
        'share_url': this.shareUrl,
        'is_verified': this.isVerified,
        'created_at': this.createdAt?.toIso8601String(),
      };
}