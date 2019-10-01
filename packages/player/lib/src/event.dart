import 'package:flutter/material.dart';
import 'package:smplayer/src/event_type.dart';
import 'package:smplayer/src/media.dart';

class Event {
  final EventType type;
  final Media media;
  final String error;
  final Duration position;
  final Duration duration;

  Event({@required this.type, @required this.media, this.error, this.position, this.duration});

  @override
  String toString() => "Event type: $type media: $media error: $error position: $position duration: $duration";

@override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          media == other.media &&
          error == other.error &&
          position == other.position &&
          duration == other.duration;

  @override
  int get hashCode => [type, media, error].hashCode;  
}
