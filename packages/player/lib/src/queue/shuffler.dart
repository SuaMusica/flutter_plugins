import 'package:smplayer/src/models/media.dart';
import 'package:smplayer/src/queue/queue_item.dart';

abstract class Shuffler {
  List<QueueItem<Media>> shuffle(List<QueueItem<Media>> list);
  List<QueueItem<Media>> unshuffle(List<QueueItem<Media>> list);
}
