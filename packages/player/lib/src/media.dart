import 'dart:convert';

import 'package:flutter/widgets.dart';

class Media {
  final String id;
  final String name;
  final String author;
  final String url;
  final bool isLocal;
  final String coverUrl;
  final bool isVerified;
  final String shareUrl;

  Media(
      {@required this.id,
      @required this.name,
      @required this.author,
      @required this.url,
      this.isLocal,
      @required this.coverUrl,
      this.isVerified,
      this.shareUrl}) : super();

  Map<String, dynamic> toJson() =>
    {
      'id': id,
      'name': name,
      'author': author,
      'url': url,
      'is_local': isLocal,
      'cover_url': coverUrl,
      'is_verified': isVerified,
      'shared_url': shareUrl
    };

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Media &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          author == other.author &&
          url == other.url &&
          isLocal == other.isLocal &&
          coverUrl == other.coverUrl &&
          isVerified == other.isVerified &&
          shareUrl == other.shareUrl;

  @override
  int get hashCode => [id, name, author, url, isLocal, coverUrl, isVerified, shareUrl].hashCode;
}
