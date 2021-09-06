import 'package:smplayer/src/media.dart';
import 'package:smplayer/src/queue_item.dart';
import 'package:smplayer/src/shuffler.dart';
import 'package:smplayer/src/simple_shuffle.dart';
import 'package:smplayer/src/repeat_mode.dart';

class Queue {
  var index = -1;
  final Shuffler _shuffler;
  var storage = <QueueItem<Media>>[];

  DateTime? _lastPrevious;

  Queue({shuffler, mode}) : _shuffler = shuffler ?? SimpleShuffler();

  Media? get current {
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

  Media? get top {
    if (this.size > 0) {
      return storage[0].item;
    }
    return null;
  }

  play(Media media) {
    if (storage.length > 0) {
      storage.replaceRange(0, 1, [QueueItem(0, 0, media)]);
    } else {
      int pos = _nextPosition();
      storage.add(QueueItem(pos, pos, media));
    }
    index = 0;
  }

  replaceCurrent(Media media) =>
      storage[index] = storage[index].copyWith(item: media);
  add(Media media) {
    int pos = _nextPosition();
    storage.add(QueueItem(pos, pos, media));
  }

  addAll(List<Media> items) {
    for (var media in items) {
      int pos = _nextPosition();
      storage.add(QueueItem(pos, pos, media));
    }
  }

  remove(Media media) {
    final itemToBeRemoved = storage.firstWhere((i) => i.item == media);
    if (itemToBeRemoved.position < index) {
      --index;
    }
    storage.remove(itemToBeRemoved);
    for (var i = itemToBeRemoved.position + 1; i < storage.length; ++i) {
      storage[i].position -= 1;
      storage[i].originalPosition -= 1;
    }
  }

  clear() => removeAll();

  removeAll() {
    storage.clear();
    index = -1;
  }

  shuffle() {
    if (storage.length > 2) {
      var current = storage.elementAt(index);
      _shuffler.shuffle(storage);
      for (var i = 0; i < storage.length; ++i) {
        storage.elementAt(i).position = i;
      }
      var currentIndex = storage.indexOf(current);
      reorder(currentIndex, 0, true);
      this.index = 0;
    }
  }

  unshuffle() {
    if (storage.length > 2) {
      var current = storage.elementAt(index);
      _shuffler.unshuffle(storage);
      for (var i = 0; i < storage.length; ++i) {
        final item = storage.elementAt(i);
        item.position = i;
      }
      this.index = current.originalPosition;
    }
  }

  _nextPosition() {
    if (storage.length == 0) return 0;
    return storage.length;
  }

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
      final diff = now.difference(_lastPrevious!).inMilliseconds;
      print("diff: $diff");
      if (diff < 3000) {
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

  Media? possiblePrevious() {
    if (index >= 0) {
      final now = DateTime.now();
      if (_lastPrevious == null) {
        return storage.elementAt(index).item;
      } else {
        final diff = now.difference(_lastPrevious!).inMilliseconds;
        if (diff < 3000) {
          var workIndex = index;
          if (index > 0) {
            --workIndex;
          }
          return storage.elementAt(workIndex).item;
        } else {
          return storage.elementAt(index).item;
        }
      }
    }
    return storage.isNotEmpty && index >= 0
        ? storage.elementAt(index).item
        : null;
  }

  Media? next() {
    if (storage.length == 0) {
      throw AssertionError("Queue is empty");
    } else if (storage.length > 0 && index < storage.length - 1) {
      var media = storage.elementAt(++index).item;
      return media;
    } else {
      return null;
    }
  }

  Media? possibleNext(RepeatMode repeatMode) {
    if (repeatMode == RepeatMode.NONE || repeatMode == RepeatMode.TRACK) {
      return _next();
    } else if (repeatMode == RepeatMode.QUEUE) {
      if (storage.length - 1 == index) {
        return storage.elementAt(0).item;
      } else {
        return _next();
      }
    } else {
      return null;
    }
  }

  Media? _next() {
    if (storage.length == 0) {
      return null;
    } else if (storage.length > 0 && index < storage.length - 1) {
      var media = storage.elementAt(index + 1).item;
      return media;
    } else {
      return null;
    }
  }

  Media? move(int pos) {
    if (storage.length == 0) {
      throw AssertionError("Queue is empty");
    } else if (storage.length > 0 && pos <= storage.length - 1) {
      var media = storage.elementAt(pos).item;
      index = pos;
      return media;
    } else {
      return null;
    }
  }

  Media? item(int pos) {
    if (storage.length == 0) {
      return null;
    } else if (storage.length > 0 && pos <= storage.length - 1) {
      return storage.elementAt(pos).item;
    } else {
      return null;
    }
  }

  Media restart() {
    index = 0;
    return storage.elementAt(0).item;
  }

  void reorder(int oldIndex, int newIndex, [bool isShuffle = false]) {
    final playingItem = storage.elementAt(index);

    if (newIndex > oldIndex) {
      for (int i = oldIndex + 1; i <= newIndex; i++) {
        if (!isShuffle) {
          storage.elementAt(i).originalPosition--;
        }
        storage.elementAt(i).position--;
      }
    } else {
      for (int i = newIndex; i < oldIndex; i++) {
        if (!isShuffle) {
          storage.elementAt(i).originalPosition++;
        }
        storage.elementAt(i).position++;
      }
    }

    storage.elementAt(oldIndex).position = newIndex;

    if (!isShuffle) {
      storage.elementAt(oldIndex).originalPosition = newIndex;
    }

    storage.sort((a, b) => a.position.compareTo(b.position));
    final playingIndex = storage.indexOf(playingItem);
    this.index = playingIndex;
  }
}
