import 'package:suamusica_player/src/queue.dart';

abstract class Shuffler {
  shuffle(List<QueueItem> list);
  unshuffle(List<QueueItem> list);
}