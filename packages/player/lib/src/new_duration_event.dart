import 'package:flutter/foundation.dart';
import 'package:suamusica_player/src/event.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'package:suamusica_player/src/media.dart';

class NewDurationEvent extends Event {
  final Duration duration;

  NewDurationEvent(
      {String id, EventType type, Media media, @required this.duration})
      : super(id: id, type: type, media: media);

  @override
  String toString() => "${super.toString()} duration: $duration";
}
