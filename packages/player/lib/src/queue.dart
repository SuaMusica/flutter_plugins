import 'package:suamusica_player/src/event.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'dart:async';

import 'package:suamusica_player/src/media.dart';
import 'package:suamusica_player/src/queue_item.dart';
import 'package:suamusica_player/src/shuffler.dart';
import 'package:suamusica_player/src/simple_shuffle.dart';

// TODO: Se estiver na última música, é o mesmo que acabar.
// TODO: ADICIONAR EVENTO DE QUEUE ENDED
// TODO: SE TIVER EM LOOP VOLTA PRA PRIMEIRA

class Queue {
  var index = -1;
  final Shuffler _shuffler;
  var storage = List<QueueItem<Media>>();
  
  DateTime _lastPrevious;

  Queue({shuffler}) : _shuffler = shuffler ?? SimpleShuffler();

  Media get current {
    if (storage.length > 0 && index >= 0) {
      return storage.elementAt(index).item;
    } else {
      return null;
    }
  }

  List<Media> get items {
    return storage.length > 0 ? List<Media>.unmodifiable((storage.map((i) => i.item).toList())) : [];
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
    storage.replaceRange(0, 1, [QueueItem(0, media)]);
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
    storage.removeWhere((i) => i.item == media);
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
    assert (index >= 0);
    return storage.elementAt(index).item;
  }

  Media previous() {
    assert (index >= 0);
    final now = DateTime.now();
    if (_lastPrevious == null) {
      _lastPrevious = now;
      return rewind();
    } else {
      if (now.difference(_lastPrevious).inMilliseconds < 1000) {
        if (index > 0) {
          --index;   
        }
        return storage.elementAt(index).item;    
      } else {
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
}
