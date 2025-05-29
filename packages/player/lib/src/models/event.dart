import 'package:smplayer/src/enums/event_type.dart';
import 'package:smplayer/src/models/media.dart';
import 'package:smplayer/src/enums/repeat_mode.dart';

class Event {
  Event({
    required this.type,
    required this.media,
    required this.queuePosition,
    this.queue,
    this.error,
    this.errorType,
    this.position,
    this.duration,
    this.idSum = 0,
    this.repeatMode = RepeatMode.REPEAT_MODE_OFF,
    this.shuffleEnabled = false,
  });

  final EventType type;
  final Media media;
  final String? error;
  final PlayerErrorType? errorType;
  final int queuePosition, idSum;
  final Duration? position;
  final Duration? duration;
  final List<Media>? queue;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;

  @override
  String toString() =>
      "Event type: $type media: $media queuePosition: $queuePosition error: $error errorType: $errorType position: $position duration: $duration";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          media == other.media &&
          queuePosition == queuePosition &&
          idSum == idSum &&
          error == other.error &&
          errorType == other.errorType &&
          position == other.position &&
          queue == other.queue &&
          duration == other.duration;

  @override
  int get hashCode => [type, media, error, errorType, queue, idSum].hashCode;
}
