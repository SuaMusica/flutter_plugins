import 'package:flutter/foundation.dart';
import 'package:suamusica_player/src/event.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'package:suamusica_player/src/media.dart';

class PositionChangeEvent extends Event {
  final Duration position;
  final Duration duration;

  PositionChangeEvent(
      {String id,
      Media media,
      @required this.position,
      @required this.duration})
      : super(type: EventType.POSITION_CHANGE, media: media);

  @override
  String toString() => "${super.toString()} position: $position duration: $duration";
}
