import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smplayer/src/previous_playlist_model.dart';

class IsarService {
  IsarService._() {
    initializeIfNeeded();
  }
  static IsarService? _instance;

  static IsarService get instance => _instance ??= IsarService._();

  PreviousPlaylistMusics? playlistMusics;

  Isar? _isarStorage;
  Future<void> initializeIfNeeded() async {
    if (_isarStorage == null) {
      debugPrint('Initializing IsarStorage');
      final directory = await getApplicationDocumentsDirectory();
      _isarStorage = await Isar.open(
        [
          PreviousPlaylistMusicsSchema,
          PreviousPlaylistPositionSchema,
          PreviousPlaylistCurrentIndexSchema,
        ],
        name: 'keepListening',
        directory: directory.path,
      );
    } else {
      _isarStorage = await Future.value(Isar.getInstance('keepListening'));
    }
  }

  Future<void> addPreviousPlaylistMusics(
    PreviousPlaylistMusics previousPlaylistMusics,
  ) async {
    await initializeIfNeeded();
    await _isarStorage?.writeTxn(
      () async {
        await _isarStorage?.previousPlaylistMusics.put(previousPlaylistMusics);
      },
    );
  }

  Future<PreviousPlaylistMusics?> getPreviousPlaylistMusics() async {
    await initializeIfNeeded();
    return await _isarStorage?.previousPlaylistMusics.get(1);
  }

  Future<void> addPreviousPlaylistCurrentIndex(
    PreviousPlaylistCurrentIndex previousPlaylistCurrentIndex,
  ) async {
    await initializeIfNeeded();
    await _isarStorage?.writeTxn(
      () async {
        await _isarStorage?.previousPlaylistCurrentIndexs
            .put(previousPlaylistCurrentIndex);
      },
    );
  }

  Future<PreviousPlaylistCurrentIndex?>
      getPreviousPlaylistCurrentIndex() async {
    await initializeIfNeeded();
    return await _isarStorage?.previousPlaylistCurrentIndexs.get(1);
  }

  Future<void> addPreviousPlaylistPosition(
    PreviousPlaylistPosition previousPlaylistPosition,
  ) async {
    if (previousPlaylistPosition.position > 0 &&
        (previousPlaylistPosition.position % 5) == 0) {
      await initializeIfNeeded();
      await _isarStorage?.writeTxn(
        () async {
          await _isarStorage?.previousPlaylistPositions
              .put(previousPlaylistPosition);
        },
      );
    }
  }

  Future<PreviousPlaylistPosition?> getPreviousPlaylistPosition() async {
    await initializeIfNeeded();
    return _isarStorage?.previousPlaylistPositions.get(1);
  }

  Future<void> removeAllMusics() async {
    await _isarStorage?.writeTxn(() async {
      await _isarStorage?.clear();
    });
  }
}
