import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class Media extends Equatable {
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
      this.shareUrl});
}
