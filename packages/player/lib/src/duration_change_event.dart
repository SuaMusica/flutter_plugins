import 'package:flutter/foundation.dart';
import 'package:smplayer/src/event.dart';
import 'package:smplayer/src/event_type.dart';
import 'package:smplayer/src/media.dart';

class DurationChangeEvent extends Event {
  final Duration duration;

  DurationChangeEvent(
      {String id, Media media, @required this.duration})
      : super(type: EventType.DURATION_CHANGE, media: media);

  @override
  String toString() => "${super.toString()} duration: $duration";
}
