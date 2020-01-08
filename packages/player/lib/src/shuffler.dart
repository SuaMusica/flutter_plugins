import 'package:smplayer/src/queue_item.dart';

import '../player.dart';

abstract class Shuffler {
  List<QueueItem<Media>> shuffle(List<QueueItem<Media>> list);
  List<QueueItem<Media>> unshuffle(List<QueueItem<Media>> list);
}
