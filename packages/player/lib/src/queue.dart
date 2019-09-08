import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:suamusica_player/src/media.dart';
import 'package:suamusica_player/src/shuffler.dart';
import 'package:suamusica_player/src/simple_shuffle.dart';

class QueueItem extends Equatable {
  final position;
  final item;
  QueueItem(this.position, this.item): super();

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is QueueItem &&
    runtimeType == other.runtimeType &&
    position == other.position &&
    item == other.item;

  @override
  int get hashCode => position.hashCode + item.hashCode;

  @override
  String toString() => "$position -> $item";
}

class Queue {
  final Shuffler shuffler;
  final storage = DoubleLinkedQueue();

  Queue({shuffler}): shuffler = shuffler ?? SimpleShuffler();

  Media get current => storage.first;

  play(Media media) {
    storage.addFirst(media);
  }

  add(Media media) {
    storage.add(media);
  }

  remove(Media media) {
    storage.remove(media);
  }

  shuffle() {
    
  }

  _nextPosition() => storage.length + 1;
}