import 'package:smplayer/src/event.dart';
import 'package:smplayer/src/media.dart';

class CurrentQueueUpdated extends Event {
  CurrentQueueUpdated({
    required super.type,
    required List<Media> queue,
    required super.queuePosition,
    required super.media,
  });
}
