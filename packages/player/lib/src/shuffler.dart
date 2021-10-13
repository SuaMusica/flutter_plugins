import 'queue_item.dart';
import 'media.dart';

abstract class Shuffler {
  List<QueueItem<Media>> shuffle(List<QueueItem<Media>> list);
  List<QueueItem<Media>> unshuffle(List<QueueItem<Media>> list);
}
