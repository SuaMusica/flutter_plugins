import 'package:flutter/material.dart';
import 'package:smplayer/src/event_type.dart';
import 'package:smplayer/src/media.dart';

class Event {
  Event(
      {@required this.type,
      @required this.media,
      @required this.queuePosition,
      this.error,
      this.position,
      this.duration});

  final EventType type;
  final Media media;
  final String error;
  final int queuePosition;
  final Duration position;
  final Duration duration;

  @override
  String toString() =>
      "Event type: $type media: $media queuePosition: $queuePosition error: $error position: $position duration: $duration";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          media == other.media &&
          queuePosition == queuePosition &&
          error == other.error &&
          position == other.position &&
          duration == other.duration;

  @override
  int get hashCode => [type, media, error].hashCode;
}
