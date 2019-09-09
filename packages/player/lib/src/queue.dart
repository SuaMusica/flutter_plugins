import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:suamusica_player/src/media.dart';
import 'package:suamusica_player/src/shuffler.dart';
import 'package:suamusica_player/src/simple_shuffle.dart';

class QueueItem<T> extends Equatable {
  final position;
  final T item;
  QueueItem(this.position, this.item) : super();

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
  var index = -1;
  final Shuffler _shuffler;
  var storage = List<QueueItem<Media>>();

  Queue({shuffler}) : _shuffler = shuffler ?? SimpleShuffler();

  Media get current {
    if (storage.length > 0 && index >= 0) {
      return storage.elementAt(index).item;
    } else {
      return null;
    }
  }

  items() => List<Media>.unmodifiable((storage.map((i) => i.item).toList()));

  addOnTop(Media media) {
    storage.insert(0, QueueItem(_nextPosition(), media));
    index = 0;
  }

  add(Media media) {
    storage.add(QueueItem(_nextPosition(), media));
  }

  remove(Media media) {
    storage.removeWhere((i) => i.item == media);
  }

  shuffle() {
    if (storage.length > 2) {
      var newStorage = _shuffler.shuffle(storage.sublist(1));
      newStorage.insert(0, storage.elementAt(0));
      storage = newStorage;
    }
  }

  unshuffle() {
    if (storage.length > 2) {
      var newStorage = _shuffler.unshuffle(storage.sublist(1));
      newStorage.insert(0, storage.elementAt(0));
      storage = newStorage;
    }
  }

  _nextPosition() => storage.length + 1;

  Media next() {
    if (storage.length > 0 && index < storage.length - 1) {
      var media = storage.elementAt(++index).item;
      print("next: $index ${media.author} - ${media.name}");
      return media;
    } else {
      return null;
    }
  }

  Media previous() {
    if (storage.length > 0 && index > 0) {
      var media = storage.elementAt(--index).item;
      print("previous: $index ${media.author} - ${media.name}");
      return media;
    } else {
      return null;
    }
  }
}
