import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smplayer/src/models/previous_playlist_model.dart';

class IsarService {
  IsarService._();
  static IsarService? _instance;

  static IsarService get instance => _instance ??= IsarService._();

  PreviousPlaylistMusics? playlistMusics;
  bool _isIsarEnabled = true;
  set isarEnabled(bool isarEnabled) => _isIsarEnabled = isarEnabled;
  Isar? _isarStorage;

  Future<void> initializeIfNeeded() async {
    try {
      if (_isarStorage == null && _isIsarEnabled) {
        debugPrint('Initializing IsarStorage');
        if (Platform.isMacOS || Platform.isLinux) {
          Isar.initializeIsarCore(
            libraries: {
              Abi.macosArm64: 'libisar_macos.dylib',
              Abi.macosX64: 'libisar_macos.dylib',
              Abi.linuxX64: 'libisar_linux_x64.so',
            },
          );
        }

        if (!(_isarStorage?.isOpen ?? false)) {
          final directory = await getApplicationDocumentsDirectory();
          debugPrint('Initializing IsarStorage isOpen');
          _isarStorage = await Isar.open(
            [
              PreviousPlaylistMusicsSchema,
              PreviousPlaylistPositionSchema,
              PreviousPlaylistCurrentIndexSchema,
            ],
            maxSizeMiB: 16,
            name: 'keepListening',
            directory: directory.path,
          );
        }
      }
    } catch (_) {}
  }

  void dispose() {
    _isarStorage?.close();
    _isarStorage = null;
  }

  Future<void> addPreviousPlaylistMusics(
    PreviousPlaylistMusics previousPlaylistMusics,
  ) async {
    await initializeIfNeeded();
    try {
      await _isarStorage?.writeTxn(() async {
        await _isarStorage?.previousPlaylistMusics.put(previousPlaylistMusics);
      }, silent: kDebugMode);
    } catch (_) {}
  }

  Future<PreviousPlaylistMusics?> getPreviousPlaylistMusics() async {
    await initializeIfNeeded();
    return _isarStorage?.previousPlaylistMusics.getSync(1);
  }

  Future<void> addPreviousPlaylistCurrentIndex(
    PreviousPlaylistCurrentIndex previousPlaylistCurrentIndex,
  ) async {
    await initializeIfNeeded();
    try {
      await _isarStorage?.writeTxn(() async {
        await _isarStorage?.previousPlaylistCurrentIndexs.put(
          previousPlaylistCurrentIndex,
        );
      }, silent: kDebugMode);
    } catch (_) {}
  }

  Future<PreviousPlaylistCurrentIndex?>
  getPreviousPlaylistCurrentIndex() async {
    await initializeIfNeeded();
    return _isarStorage?.previousPlaylistCurrentIndexs.getSync(1);
  }

  Future<void> addPreviousPlaylistPosition(
    PreviousPlaylistPosition previousPlaylistPosition,
  ) async {
    await initializeIfNeeded();
    try {
      await _isarStorage?.writeTxn(() async {
        await _isarStorage?.previousPlaylistPositions.put(
          previousPlaylistPosition,
        );
      }, silent: kDebugMode);
    } catch (_) {}
  }

  Future<PreviousPlaylistPosition?> getPreviousPlaylistPosition() async {
    await initializeIfNeeded();
    return _isarStorage?.previousPlaylistPositions.getSync(1);
  }

  Future<void> removeAllMusics() async =>
      await _isarStorage?.writeTxn(() async {
        await _isarStorage?.clear();
      }, silent: kDebugMode);
}
