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
    Shuffler? shuffler,
    this.initializeIsar = false,
    this.onInitialize,
    this.beforeInitialize,
  }) : _shuffler = shuffler ?? SimpleShuffler() {
    IsarService.instance.isarEnabled = initializeIsar;
    itemsReady = !initializeIsar;
    _initialize();
  }

  Future<void> _initialize() async {
    if (!itemsReady) {
      try {
        await beforeInitialize?.call();

        final results = await Future.wait([
          previousItems,
          previousPlaylistIndex,
          _previousPlaylistPosition,
        ]);

        final items = results[0] as List<Media>;
        previousIndex = results[1] as int;
        previousPosition = results[2] as PreviousPlaylistPosition?;

        if (items.isNotEmpty) {
          playerQueue.addAll(
            items.asMap().entries.map(
              (entry) => QueueItem(entry.key, entry.key, entry.value),
            ),
          );
          await onInitialize?.call(items);
        }
        itemsReady = true;
      } catch (e) {
        debugPrint('#APP LOGS ==> Error initializing Queue: $e');
        itemsReady = true;
      }
    }
  }

  var _index = 0;
  int get index => _index;
  Media? _current;

  set setIndex(int index) {
    if (playerQueue.isEmpty || index < 0 || index >= playerQueue.length) {
      _index = -1;
      _current = null;
      return;
    }

    _index = index;
    _current = playerQueue[index].item;
  }

  final Shuffler _shuffler;
  final bool initializeIsar;
  final Future<void> Function(List<Media>)? onInitialize;
  final Future<void> Function()? beforeInitialize;
  bool itemsReady = false;
  int previousIndex = 0;
  PreviousPlaylistPosition? previousPosition;
  List<QueueItem<Media>> playerQueue = <QueueItem<Media>>[];
  PreviousPlaylistMusics? previousPlaylistMusics;
  DateTime? _lastPrevious;
  Media? get current =>
      _current ??
      (index >= 0 && index < playerQueue.length
          ? playerQueue[index].item
          : null);

  List<Media> get items {
    return playerQueue.length > 0
        ? List<Media>.unmodifiable((playerQueue.map((i) => i.item).toList()))
        : [];
  }

  Future<List<Media>> get previousItems async {
    previousPlaylistMusics = await IsarService.instance
        .getPreviousPlaylistMusics();
    return previousPlaylistMusics?.musics?.toListMedia ?? [];
  }

  Future<PreviousPlaylistPosition?> get _previousPlaylistPosition async {
    final previousPlaylistPosition = await IsarService.instance
        .getPreviousPlaylistPosition();
    return previousPlaylistPosition?.position != null
        ? previousPlaylistPosition
        : null;
  }

  Future<int> get previousPlaylistIndex async {
    final previousPlaylistCurrentIndex = await IsarService.instance
        .getPreviousPlaylistCurrentIndex();
    return previousPlaylistCurrentIndex?.currentIndex ?? 0;
  }

  int get size => playerQueue.length;

  Media? get top {
    if (this.size > 0) {
      return playerQueue[0].item;
    }
    return null;
  }

  List<QueueItem<Media>> _toQueueItems(List<Media> items, int i) {
    return items.map((e) {
      i++;
      return QueueItem(i, i, e);
    }).toList();
  }

  addAll(List<Media> items, {bool saveOnTop = false}) async {
    int i = playerQueue.length == 1 ? 0 : playerQueue.length - 1;
    if (saveOnTop) {
      playerQueue.insertAll(0, _toQueueItems(items, i));
    } else {
      playerQueue.addAll(_toQueueItems(items, i));
    }

    await _save(medias: items, saveOnTop: saveOnTop);
  }

  Future<void> _save({
    required List<Media> medias,
    bool saveOnTop = false,
  }) async {
    final items = await previousItems;
    debugPrint(
      '[TESTE] itemsFromStorage: ${items.length} - mediasToSave: ${medias.length}',
    );

    await IsarService.instance.addPreviousPlaylistMusics(
      PreviousPlaylistMusics(musics: organizeLists(saveOnTop, items, medias)),
    );
  }

  /// Organizes two media lists into a single list of compressed strings.
  ///
  /// This function is responsible for combining two media lists (`items` and `medias`) into a single
  /// list of strings, determining the order based on the `saveOnTop` parameter.
  ///
  /// Parameters:
  /// * [saveOnTop] - A boolean that determines the order of list combination:
  ///   - If `true`: the `medias` list will be placed on top
  ///   - If `false`: the `items` list will be placed on top
  /// * [items] - First media list to be combined
  /// * [medias] - Second media list to be combined
  ///
  /// Returns:
  /// * A list of strings containing the compressed representations of the media in the determined order
  ///
  /// Usage example:
  /// ```dart
  /// final result = organizeLists(
  ///   saveOnTop: true,
  ///   items: [media1, media2],
  ///   medias: [media3, media4]
  /// );
  /// // If saveOnTop is true, the result will be [media3, media4, media1, media2]
  /// // If saveOnTop is false, the result will be [media1, media2, media3, media4]
  /// ```
  ///
  /// Notes:
  /// * The function uses the `toListStringCompressed` method of the media lists to convert
  ///   Media objects into compressed strings
  /// * The order of the lists is determined by the `saveOnTop` parameter, which controls which list
  ///   will be placed at the beginning of the resulting list
  /// * This function is commonly used to organize playlists and manage the playback order
  ///   of media in the player
  List<String> organizeLists(
    bool saveOnTop,
    List<Media> items,
    List<Media> medias,
  ) {
    final List<Media> topList = saveOnTop ? medias : items;
    final List<Media> bottomList = saveOnTop ? items : medias;

    return [
      ...topList.toListStringCompressed,
      ...bottomList.toListStringCompressed,
    ];
  }

  int removeByPosition({
    required List<int> positionsToDelete,
    required bool isShuffle,
  }) {
    try {
      int lastLength = playerQueue.length;
      for (var i = 0; i < positionsToDelete.length; ++i) {
        final pos = positionsToDelete[i] - i;
        if (pos < index) {
          setIndex = index - 1;
        }
        playerQueue.removeAt(pos);
      }

      for (var j = 0; j < playerQueue.length; ++j) {
        playerQueue[j].position = j;
      }

      if (kDebugMode) {
        for (var e in playerQueue) {
          debugPrint(
            '=====> storage remove: ${e.item.name} - ${e.position} | ${e.originalPosition}',
          );
        }
      }
      return lastLength - playerQueue.length;
    } catch (e) {
      return 0;
    }
  }

  clear() => removeAll();

  removeAll() {
    playerQueue.clear();
    setIndex = 0;
  }

  shuffle() {
    if (playerQueue.length > 2) {
      var current = playerQueue[index];
      _shuffler.shuffle(playerQueue);
      for (var i = 0; i < playerQueue.length; ++i) {
        playerQueue[i].position = i;
      }
      var currentIndex = playerQueue.indexOf(current);
      reorder(currentIndex, 0, true);
      setIndex = 0;
    }
  }

  unshuffle() {
    if (playerQueue.length > 2) {
      var current = playerQueue[index];
      _shuffler.unshuffle(playerQueue);
      for (var i = 0; i < playerQueue.length; ++i) {
        final item = playerQueue[i];
        item.position = i;
      }
      if (kDebugMode) {
        for (var e in playerQueue) {
          debugPrint(
            '=====> storage unshuffle: ${e.item.name} - ${e.position} | ${e.originalPosition}',
          );
        }
      }
      setIndex = current.position;
    }
  }

  bool shouldRewind() {
    if (index >= 0) {
      final now = DateTime.now();
      if (_lastPrevious == null) {
        _lastPrevious = now;
        return true;
      } else {
        final diff = now.difference(_lastPrevious!).inMilliseconds;
        _lastPrevious = now;
        return diff > 3000;
      }
    }
    return false;
  }

  Media? possiblePrevious() {
    if (index >= 0) {
      var workIndex = index;
      if (index > 0) {
        --workIndex;
      }
      return playerQueue[workIndex].item;
    }
    return playerQueue.isNotEmpty && index >= 0
        ? playerQueue[index].item
        : null;
  }

  Media? possibleNext(RepeatMode repeatMode) {
    if (repeatMode == RepeatMode.REPEAT_MODE_OFF ||
        repeatMode == RepeatMode.REPEAT_MODE_ONE) {
      return _next();
    } else if (repeatMode == RepeatMode.REPEAT_MODE_ALL) {
      if (playerQueue.length - 1 == index) {
        return playerQueue[0].item;
      } else {
        return _next();
      }
    } else {
      return null;
    }
  }

  Media? _next() {
    if (playerQueue.length == 0) {
      return null;
    } else if (playerQueue.length > 0 && index < playerQueue.length - 1) {
      var media = playerQueue[index + 1].item;
      return media;
    } else {
      return null;
    }
  }

  Media? move(int pos) {
    if (playerQueue.length == 0) {
      throw AssertionError("Queue is empty");
    } else if (playerQueue.length > 0 && pos <= playerQueue.length - 1) {
      var media = playerQueue[pos].item;
      setIndex = pos;
      return media;
    } else {
      return null;
    }
  }

  void updateIsarIndex(int id, int newIndex) async {
    IsarService.instance.addPreviousPlaylistCurrentIndex(
      PreviousPlaylistCurrentIndex(mediaId: id, currentIndex: newIndex),
    );
  }

  Media restart() {
    setIndex = 0;
    return playerQueue.first.item;
  }

  reorder(int oldIndex, int newIndex, [bool isShuffle = false]) {
    final playingItem = playerQueue.elementAt(index);
    if (newIndex > oldIndex) {
      for (int i = oldIndex + 1; i <= newIndex; i++) {
        if (!isShuffle) {
          playerQueue[i].originalPosition--;
        }
        playerQueue[i].position--;
      }
    } else {
      for (int i = newIndex; i < oldIndex; i++) {
        if (!isShuffle) {
          playerQueue[i].originalPosition++;
        }
        playerQueue[i].position++;
      }
    }

    playerQueue[oldIndex].position = newIndex;
    if (!isShuffle) {
      playerQueue[oldIndex].originalPosition = newIndex;
    }
    playerQueue.sort((a, b) => a.position.compareTo(b.position));
    final playingIndex = playerQueue.indexOf(playingItem);

    if (kDebugMode) {
      debugPrint(
        '=====> ${playerQueue[oldIndex].item.name} - playerQueue[oldIndex]: ${playerQueue[oldIndex].originalPosition}',
      );
      debugPrint(
        '=====> ${playerQueue[newIndex].item.name} - playerQueue[newIndex]: ${playerQueue[newIndex].originalPosition}',
      );
      for (var e in playerQueue) {
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
