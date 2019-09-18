import 'package:flutter/material.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'package:suamusica_player/src/media.dart';
import 'package:uuid/uuid.dart';

class Event {
  static final _uuid = Uuid();
  final String id;
  final EventType type;
  final Media media;
  final String error;

  Event({id, @required this.type, @required this.media, this.error}) : id = id ?? _uuid.v4();

  @override
  String toString() => "Event id: $id type: $type media: $media error: $error";

@override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          media == other.media &&
          error == other.error;

  @override
  int get hashCode => [id, type, media, error].hashCode;  
}
