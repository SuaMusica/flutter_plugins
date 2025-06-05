import 'package:smplayer/src/models/event.dart';
import 'package:smplayer/src/enums/event_type.dart';
import 'package:smplayer/src/models/media.dart';

class PositionChangeEvent extends Event {
  final Duration position;
  final Duration duration;

  PositionChangeEvent({
    required Media media,
    required int queuePosition,
    required this.position,
    required this.duration,
  }) : super(
         type: EventType.POSITION_CHANGE,
         media: media,
         queuePosition: queuePosition,
       );

  @override
  String toString() =>
      "${super.toString()} position: $position duration: $duration";
}
