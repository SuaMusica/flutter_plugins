import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smplayer/src/isar_service.dart';
import 'package:smplayer/src/media.dart';
import 'package:smplayer/src/previous_playlist_model.dart';
import 'package:smplayer/src/queue_item.dart';

class Queue {
  Queue({
    this.initializeIsar = false,
  }) {
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

  final bool initializeIsar;
  bool itemsReady = false;
  int previousIndex = 0;
  PreviousPlaylistPosition? previousPosition;
  var storage = <QueueItem<Media>>[];
  PreviousPlaylistMusics? previousPlaylistMusics;

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

  addAll(
    List<Media> items, {
    bool shouldRemoveFirst = false,
    bool saveOnTop = false,
  }) async {
    await save(medias: items, saveOnTop: saveOnTop);
  }

  Future<void> save(
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
  //   }

  void dispose() {
    IsarService.instance.dispose();
  }
}
