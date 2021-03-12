import 'dart:convert';

class Media {
  final int id;
  final String name;
  final int ownerId;
  final int albumId;
  final String albumTitle;
  final String author;
  String url;
  bool isLocal;
  final String? localPath;
  final String coverUrl;
  final String bigCoverUrl;
  final bool isVerified;
  final String? shareUrl;
  final int? playlistId;
  final bool isSpot;
  final bool? isFavorite;
  String? fallbackUrl;
  Media({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.author,
    required this.url,
    required this.albumId,
    required this.albumTitle,
    this.isLocal = false,
    required this.coverUrl,
    required this.bigCoverUrl,
    this.isVerified = false,
    this.localPath,
    this.shareUrl,
    this.playlistId,
    this.isSpot = false,
    this.fallbackUrl,
    this.isFavorite,
  }) : super() {
    fallbackUrl = fallbackUrl ?? url;
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerId': ownerId,
        'albumId': albumId,
        'albumTitle': albumTitle,
        'author': author,
        'url': url,
        'is_local': isLocal,
        'cover_url': coverUrl,
        'bigCover': bigCoverUrl,
        'is_verified': isVerified,
        'shared_url': shareUrl,
        'playlist_id': playlistId,
        'fallbackUrl': fallbackUrl,
        'is_spot': isSpot,
        'isFavorite': isFavorite,
      };

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Media &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          albumId == other.albumId &&
          albumTitle == other.albumTitle &&
          name == other.name &&
          ownerId == other.ownerId &&
          author == other.author &&
          url == other.url &&
          isLocal == other.isLocal &&
          coverUrl == other.coverUrl &&
          isVerified == other.isVerified &&
          shareUrl == other.shareUrl &&
          playlistId == other.playlistId &&
          fallbackUrl == other.fallbackUrl &&
          isFavorite == other.isFavorite &&
          isSpot == other.isSpot;

  @override
  int get hashCode => [
        id,
        name,
        albumId,
        albumTitle,
        ownerId,
        author,
        url,
        isLocal,
        coverUrl,
        isVerified,
        shareUrl,
        playlistId,
        isSpot,
        isFavorite,
      ].hashCode;

  Media copyWith({
    int? id,
    String? name,
    int? ownerId,
    int? albumId,
    String? albumTitle,
    String? author,
    String? url,
    bool? isLocal,
    String? localPath,
    String? coverUrl,
    String? bigCoverUrl,
    bool? isVerified,
    String? shareUrl,
    int? playlistId,
    bool? isSpot,
    bool? isFavorite,
    String? fallbackUrl,
  }) =>
      Media(
        id: id ?? this.id,
        name: name ?? this.name,
        ownerId: ownerId ?? this.ownerId,
        albumId: albumId ?? this.albumId,
        albumTitle: albumTitle ?? this.albumTitle,
        author: author ?? this.author,
        url: url ?? this.url,
        isLocal: isLocal ?? this.isLocal,
        coverUrl: coverUrl ?? this.coverUrl,
        bigCoverUrl: bigCoverUrl ?? this.bigCoverUrl,
        isVerified: isVerified ?? this.isVerified,
        shareUrl: shareUrl ?? this.shareUrl,
        playlistId: playlistId ?? this.playlistId,
        fallbackUrl: fallbackUrl ?? this.fallbackUrl,
        isSpot: isSpot ?? this.isSpot,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}
