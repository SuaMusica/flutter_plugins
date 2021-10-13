import 'event_type.dart';
import 'media.dart';

class Event {
  Event({
    required this.type,
    required this.media,
    required this.queuePosition,
    this.error,
    this.errorType,
    this.position,
    this.duration,
  });

  final EventType type;
  final Media media;
  final String? error;
  final PlayerErrorType? errorType;
  final int queuePosition;
  final Duration? position;
  final Duration? duration;

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
          error == other.error &&
          errorType == other.errorType &&
          position == other.position &&
          duration == other.duration;

  @override
  int get hashCode => [type, media, error, errorType].hashCode;
}
