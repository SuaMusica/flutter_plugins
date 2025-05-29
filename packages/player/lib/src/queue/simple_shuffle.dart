import 'package:smplayer/src/models/media.dart';
import 'package:smplayer/src/queue/queue_item.dart';
import 'package:smplayer/src/queue/shuffler.dart';

class SimpleShuffler extends Shuffler {
  List<QueueItem<Media>> shuffle(List<QueueItem<Media>> list) {
    ArgumentError.checkNotNull(list);
    list.shuffle();
    return list;
  }

  List<QueueItem<Media>> unshuffle(List<QueueItem<Media>> list) {
    ArgumentError.checkNotNull(list);
    list.sort((a, b) => a.originalPosition.compareTo(b.originalPosition));
    return list;
  }
}
