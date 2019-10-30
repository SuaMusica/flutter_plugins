import 'package:smplayer/src/media.dart';
import 'package:smplayer/src/queue_item.dart';
import 'package:smplayer/src/shuffler.dart';
import 'package:smplayer/src/simple_shuffle.dart';

class Queue {
  var index = -1;
  final Shuffler _shuffler;
  var storage = List<QueueItem<Media>>();

  DateTime _lastPrevious;

  Queue({shuffler, mode}) : _shuffler = shuffler ?? SimpleShuffler();

  Media get current {
    if (storage.length > 0 && index >= 0) {
      return storage.elementAt(index).item;
    } else {
      return null;
    }
  }

  List<Media> get items {
    return storage.length > 0
        ? List<Media>.unmodifiable((storage.map((i) => i.item).toList()))
        : [];
  }

  int get size => storage.length;

  Media get top {
    if (this.size > 0) {
      return storage[0].item;
    }
    return null;
  }

  play(Media media) {
    ArgumentError.checkNotNull(media);
    if (storage.length > 0) {
      storage.replaceRange(0, 1, [QueueItem(0, media)]);
    } else {
      storage.add(QueueItem(_nextPosition(), media));
    }
    index = 0;
  }

  add(Media media) {
    ArgumentError.checkNotNull(media);
    storage.add(QueueItem(_nextPosition(), media));
  }

  addAll(List<Media> items) {
    ArgumentError.checkNotNull(items);
    for (var media in items) {
      storage.add(QueueItem(_nextPosition(), media));
    }
  }

  remove(Media media) {
    ArgumentError.checkNotNull(media);
    final itemToBeRemoved = storage.firstWhere((i) => i.item == media);
    if (itemToBeRemoved.position < index) {
      --index;
    }
    storage.remove(itemToBeRemoved);
    for (var i = 0; i < storage.length; ++i) {
      storage[i].position = i;
    }
  }

  clear() => removeAll();

  removeAll() {
    storage.clear();
    index = -1;
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

  Media rewind() {
    assert(index >= 0);
    return storage.elementAt(index).item;
  }

  Media previous() {
    assert(index >= 0);
    final now = DateTime.now();
    if (_lastPrevious == null) {
      _lastPrevious = now;
      return rewind();
    } else {
      final diff = now.difference(_lastPrevious).inMilliseconds;
      print("diff: $diff");
      if (diff < 1000) {
        if (index > 0) {
          --index;
        }
        return storage.elementAt(index).item;
      } else {
        _lastPrevious = now;
        return rewind();
      }
    }
  }

  Media next() {
    if (storage.length == 0) {
      throw AssertionError("Queue is empty");
    } else if (storage.length > 0 && index < storage.length - 1) {
      var media = storage.elementAt(++index).item;
      return media;
    } else {
      return null;
    }
  }

  Media move(int pos) {
    if (storage.length == 0) {
      throw AssertionError("Queue is empty");
    } else if (storage.length > 0 && pos < storage.length - 1) {
      var media = storage.elementAt(pos).item;
      index = pos;
      return media;
    } else {
      return null;
    }
  }

  Media restart() {
    index = -1;
    return next();
  }

  void reorder(int oldIndex, int newIndex) {
    final oldItem = storage.getRange(oldIndex, oldIndex + 1);
    oldItem.first.position = newIndex;
    final newItem = storage.getRange(newIndex, newIndex + 1);
    newItem.first.position = oldIndex;
    storage.sort((a, b) => a.position.compareTo(b.position));
  }
}
