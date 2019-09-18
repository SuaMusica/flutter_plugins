import 'package:flutter/foundation.dart';
import 'package:suamusica_player/src/event.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'package:suamusica_player/src/media.dart';

class DurationChangeEvent extends Event {
  final Duration duration;

  DurationChangeEvent(
      {String id, Media media, @required this.duration})
      : super(id: id, type: EventType.DURATION_CHANGE, media: media);

  @override
  String toString() => "${super.toString()} duration: $duration";
}
