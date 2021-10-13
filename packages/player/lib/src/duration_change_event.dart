import 'event.dart';
import 'media.dart';
import 'event_type.dart';

class DurationChangeEvent extends Event {
  final Duration duration;

  DurationChangeEvent({
    String? id,
    required Media media,
    required this.duration,
    required queuePosition,
  }) : super(
          type: EventType.DURATION_CHANGE,
          media: media,
          queuePosition: queuePosition,
        );

  @override
  String toString() => "${super.toString()} duration: $duration";
}
