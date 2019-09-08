import 'package:flutter/foundation.dart';
import 'package:suamusica_player/src/event.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'package:suamusica_player/src/media.dart';

class NewPositionEvent extends Event {
  final Duration position;
  final Duration duration;

  NewPositionEvent(
      {String id,
      EventType type,
      Media media,
      @required this.position,
      @required this.duration})
      : super(id: id, type: type, media: media);

  @override
  String toString() => "${super.toString()} position: $position duration: $duration";
}
