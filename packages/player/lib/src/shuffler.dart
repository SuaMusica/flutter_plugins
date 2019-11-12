import 'package:smplayer/src/queue_item.dart';

abstract class Shuffler {
  List<QueueItem> shuffle(List<QueueItem> list);
  List<QueueItem> unshuffle(List<QueueItem> list);
}