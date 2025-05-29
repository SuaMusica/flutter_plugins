import 'package:smplayer/src/events/event.dart';
import 'package:smplayer/src/models/media.dart';

class CurrentQueueUpdated extends Event {
  CurrentQueueUpdated({
    required super.type,
    required List<Media> queue,
    required super.queuePosition,
    required super.media,
  });
}
