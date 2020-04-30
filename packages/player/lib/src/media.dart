import 'dart:convert';

import 'package:flutter/widgets.dart';

class Media {
  final int id;
  final String name;
  final int ownerId;
  final int albumId;
  final String albumTitle;
  final String author;
  String url;
  bool isLocal;
  final String coverUrl;
  final bool isVerified;
  final String shareUrl;
  final int playlistId;
  final bool isSpot;

  Media({
    @required this.id,
    @required this.name,
    @required this.ownerId,
    @required this.author,
    @required this.url,
    @required this.albumId,
    @required this.albumTitle,
    this.isLocal,
    @required this.coverUrl,
    this.isVerified,
    this.shareUrl,
    this.playlistId,
    this.isSpot,
  }) : super();

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
        'is_verified': isVerified,
        'shared_url': shareUrl,
        'playlist_id': playlistId,
        'is_spot': isSpot,
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
      ].hashCode;
}
