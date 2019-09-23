import 'package:flutter/material.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'package:suamusica_player/src/media.dart';

class Event {
  final EventType type;
  final Media media;
  final String error;

  Event({@required this.type, @required this.media, this.error});

  @override
  String toString() => "Event type: $type media: $media error: $error";

@override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          media == other.media &&
          error == other.error;

  @override
  int get hashCode => [type, media, error].hashCode;  
}
