import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smplayer/src/isar_service.dart';
import 'package:smplayer/src/media.dart';
import 'package:smplayer/src/previous_playlist_model.dart';
import 'package:smplayer/src/queue_item.dart';
import 'package:smplayer/src/repeat_mode.dart';
import 'package:smplayer/src/shuffler.dart';
import 'package:smplayer/src/simple_shuffle.dart';

class Queue {
  Queue({
    shuffler,
    mode,
    this.initializeIsar = false,
  }) : _shuffler = shuffler ?? SimpleShuffler() {
    IsarService.instance.isarEnabled = initializeIsar;
    itemsReady = !initializeIsar;
    _initialize();
  }

  Future<void> _initialize() async {
    if (!itemsReady) {
      try {
        final items = await previousItems;
        previousIndex = await previousPlaylistIndex;
        previousPosition = await _previousPlaylistPosition;
        int i = 0;
        storage.addAll(items.map((e) => QueueItem(i++, i, e)));
      } catch (_) {
      } finally {
        itemsReady = true;
      }
    }
  }

  var _index = 0;
  int get index => _index;
  Media? _current;

  set setIndex(int index) {
    if (storage.isNotEmpty && index >= 0 && index < storage.length) {
      _index = index;
      _current = storage[index].item;
    }
  }

  final Shuffler _shuffler;
  final bool initializeIsar;
  bool itemsReady = false;
  int previousIndex = 0;
  PreviousPlaylistPosition? previousPosition;
  var storage = <QueueItem<Media>>[];
  PreviousPlaylistMusics? previousPlaylistMusics;
  DateTime? _lastPrevious;

  Media? get current =>
      _current ??
      (index >= 0 && index < storage.length ? storage[index].item : null);

  List<Media> get items {
    return storage.length > 0
        ? List<Media>.unmodifiable((storage.map((i) => i.item).toList()))
        : [];
  }

  Future<List<Media>> get previousItems async {
    previousPlaylistMusics =
        await IsarService.instance.getPreviousPlaylistMusics();
    return previousPlaylistMusics?.musics?.toListMedia ?? [];
  }

  Future<PreviousPlaylistPosition?> get _previousPlaylistPosition async {
    final previousPlaylistPosition =
        await IsarService.instance.getPreviousPlaylistPosition();
    return previousPlaylistPosition?.position != null
        ? previousPlaylistPosition
        : null;
  }

  Future<int> get previousPlaylistIndex async {
    final previousPlaylistCurrentIndex =
        await IsarService.instance.getPreviousPlaylistCurrentIndex();
    return previousPlaylistCurrentIndex?.currentIndex ?? 0;
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
    _save(medias: [media]);
    setIndex = 0;
  }

  replaceCurrent(Media media) =>
      storage[index] = storage[index].copyWith(item: media);

  add(Media media) async {
    int pos = _nextPosition();
    storage.add(QueueItem(pos, pos, media));
    await _save(medias: [media]);
  }

  List<QueueItem<Media>> _toQueueItems(List<Media> items, int i) {
    return items.map(
      (e) {
        i++;
        return QueueItem(i, i, e);
      },
    ).toList();
  }

  addAll(
    List<Media> items, {
    bool shouldRemoveFirst = false,
    bool saveOnTop = false,
  }) async {
    final medias = shouldRemoveFirst ? items.sublist(1) : items;

    int i = storage.length == 1 ? 0 : storage.length - 1;
    if (saveOnTop) {
      storage.insertAll(0, _toQueueItems(medias, i));
    } else {
      storage.addAll(_toQueueItems(medias, i));
    }

    await _save(medias: items, saveOnTop: saveOnTop);
  }

  Future<void> _save(
      {required List<Media> medias, bool saveOnTop = false}) async {
    final items = await previousItems;
    debugPrint(
      '[TESTE] itemsFromStorage: ${items.length} - mediasToSave: ${medias.length}',
    );

    await IsarService.instance.addPreviousPlaylistMusics(
      PreviousPlaylistMusics(musics: organizeLists(saveOnTop, items, medias)),
    );
  }

  List<String> organizeLists(
    bool saveOnTop,
    List<Media> items,
    List<Media> medias,
  ) {
    final List<Media> topList = saveOnTop ? medias : items;
    final List<Media> bottomList = saveOnTop ? items : medias;

    return [
      ...topList.toListStringCompressed,
      ...bottomList.toListStringCompressed
    ];
  }

  int remove({required Media media, required bool isShuffle}) {
    try {
      final itemToBeRemoved = storage.firstWhere(
        (i) => i.item.id == media.id,
      );

      storage.remove(itemToBeRemoved);
      if (itemToBeRemoved.position < index) {
        setIndex = index - 1;
      }
      if (!isShuffle) {
        for (var i = itemToBeRemoved.position; i < storage.length; ++i) {
          storage[i].position--;
          storage[i].originalPosition--;
        }
      } else {
        for (var i = 0; i < storage.length; ++i) {
          storage[i].position = i;
          if (storage[i].originalPosition > itemToBeRemoved.originalPosition) {
            storage[i].originalPosition--;
          }
        }
      }

      if (kDebugMode) {
        for (var e in storage) {
          debugPrint(
              '=====> storage remove: ${e.item.name} - ${e.position} | ${e.originalPosition}');
        }
      }
    } catch (e) {
      return 0;
    }
    return 1;
  }

  clear() => removeAll();

  removeAll() {
    storage.clear();
    setIndex = 0;
  }

  shuffle() {
    if (storage.length > 2) {
      var current = storage[index];
      _shuffler.shuffle(storage);
      for (var i = 0; i < storage.length; ++i) {
        storage[i].position = i;
      }
      var currentIndex = storage.indexOf(current);
      reorder(currentIndex, 0, true);
      setIndex = 0;
    }
  }

  unshuffle() {
    if (storage.length > 2) {
      var current = storage[index];
      _shuffler.unshuffle(storage);
      for (var i = 0; i < storage.length; ++i) {
        final item = storage[i];
        item.position = i;
      }
      setIndex = current.originalPosition;
    }
  }

  _nextPosition() {
    if (storage.length == 0) return 0;
    return storage.length;
  }

  Media rewind() {
    assert(index >= 0 && index < storage.length);
    return storage[index].item;
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
          setIndex = index - 1;
        }
        return storage[index].item;
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
        return storage[index].item;
      } else {
        final diff = now.difference(_lastPrevious!).inMilliseconds;
        if (diff < 3000) {
          var workIndex = index;
          if (index > 0) {
            --workIndex;
          }
          return storage[workIndex].item;
        } else {
          return storage[index].item;
        }
      }
    }
    return storage.isNotEmpty && index >= 0 ? storage[index].item : null;
  }

  Media? next() {
    if (storage.length == 0) {
      throw AssertionError("Queue is empty");
    } else if (storage.length > 0 && index < storage.length - 1) {
      final newIndex = index + 1;
      setIndex = newIndex;
      var media = storage[newIndex].item;
      _updateIndex(media.id, newIndex);
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
        return storage[0].item;
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
      var media = storage[index + 1].item;
      return media;
    } else {
      return null;
    }
  }

  Media? move(int pos) {
    if (storage.length == 0) {
      throw AssertionError("Queue is empty");
    } else if (storage.length > 0 && pos <= storage.length - 1) {
      var media = storage[pos].item;
      setIndex = pos;
      return media;
    } else {
      return null;
    }
  }

  void _updateIndex(int id, int newIndex) async {
    IsarService.instance.addPreviousPlaylistCurrentIndex(
      PreviousPlaylistCurrentIndex(mediaId: id, currentIndex: newIndex),
    );
  }

  Media? item(int pos) {
    final item = storage[pos].item;
    _updateIndex(item.id, pos);
    if (storage.length == 0) {
      return null;
    } else if (storage.length > 0 && pos <= storage.length - 1) {
      return item;
    } else {
      return null;
    }
  }

  Media restart() {
    setIndex = 0;
    return storage.first.item;
  }

  void reorder(int oldIndex, int newIndex, [bool isShuffle = false]) {
    final playingItem = storage.elementAt(index);
    if (newIndex > oldIndex) {
      for (int i = oldIndex; i <= newIndex; i++) {
        if (!isShuffle && storage[i].originalPosition > 0) {
          storage[i].originalPosition--;
        }
        storage[i].position--;
      }
    } else {
      for (int i = newIndex; i < oldIndex; i++) {
        if (!isShuffle) {
          storage[i].originalPosition++;
        }
        storage[i].position++;
      }
    }

    storage[oldIndex].position = newIndex;
    if (!isShuffle) {
      storage[oldIndex].originalPosition = newIndex;
    }
    storage.sort((a, b) => a.position.compareTo(b.position));
    final playingIndex = storage.indexOf(playingItem);

    if (kDebugMode) {
      debugPrint(
        '=====> ${storage[oldIndex].item.name} - storage[oldIndex]: ${storage[oldIndex].originalPosition}',
      );
      debugPrint(
        '=====> ${storage[newIndex].item.name} - storage[newIndex]: ${storage[newIndex].originalPosition}',
      );
      for (var e in storage) {
        debugPrint(
          '=====> storage Reorder: ${e.item.name} - ${e.position} - ${e.originalPosition}',
        );
      }
    }

    setIndex = playingIndex;
  }

  void dispose() {
    IsarService.instance.dispose();
  }
}
