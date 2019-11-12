import 'package:smplayer/src/queue_item.dart';
import 'package:smplayer/src/shuffler.dart';

class SimpleShuffler extends Shuffler {
  List<QueueItem> shuffle(List<QueueItem> list) {
    ArgumentError.checkNotNull(list);
    list.shuffle();
    return list;
  }

  List<QueueItem> unshuffle(List<QueueItem> list) {
    ArgumentError.checkNotNull(list);
    list.sort((a, b) => a.originalPosition.compareTo(b.originalPosition));
    return list;
  }
}
