import 'package:suamusica_player/src/queue.dart';
import 'package:suamusica_player/src/shuffler.dart';

class SimpleShuffler extends Shuffler {
  shuffle(List<QueueItem> list) {
    ArgumentError.checkNotNull(list);
    list.shuffle();
    return list;
  }

  unshuffle(List<QueueItem> list) {
    ArgumentError.checkNotNull(list);
    list.sort((a, b) => a.position.compareTo(b.position));
    return list;
  }
}
