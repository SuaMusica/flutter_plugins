import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:smaws/aws.dart';
import 'package:smplayer/src/event.dart';
import 'package:smplayer/src/event_type.dart';
import 'package:smplayer/src/isar_service.dart';
import 'package:smplayer/src/media.dart';
import 'package:smplayer/src/position_change_event.dart';
import 'package:smplayer/src/previous_playlist_model.dart';
import 'package:smplayer/src/queue.dart';
import 'package:smplayer/src/repeat_mode.dart';
import 'package:smplayer/src/player_channel.dart';
import 'package:smplayer/src/player_event_controller.dart';

import 'player_state.dart';

class Player {
  Player({
    required this.playerId,
    required this.cookieSigner,
    required this.localMediaValidator,
    this.initializeIsar = false,
    this.autoPlay = false,
  }) {
    _queue = Queue(
      beforeInitialize: () async =>
          await _playerChannel.invokeMethod('remove_all'),
      initializeIsar: this.initializeIsar,
      onInitialize: (List<Media> items) async {
        await enqueueAll(items, alreadyAddedToStorage: true);
      },
    );
    eventController = PlayerEventController();
  }

  // Static variables
  static bool logEnabled = false;
  static RepeatMode _repeatMode = RepeatMode.REPEAT_MODE_OFF;
  static bool _shuffleEnabled = false;
  static const ok = PlayerChannel.ok;
  static const notOk = PlayerChannel.notOk;

  // Required constructor parameters
  final String playerId;
  final Future<CookiesForCustomPolicy?> Function() cookieSigner;
  final String? Function(Media)? localMediaValidator;
  final bool autoPlay;

  // State variables
  bool initializeIsar;
  bool externalPlayback = false;
  PlayerState state = PlayerState.IDLE;
  CookiesForCustomPolicy? _cookies;

  // Queue and event management
  late Queue _queue;
  late final PlayerChannel _playerChannel = PlayerChannel(this);
  late final PlayerEventController eventController;

  // ChromeCast related
  final chromeCastEnabledEvents = [
    EventType.BEFORE_PLAY,
    EventType.NEXT,
    EventType.PREVIOUS,
    EventType.POSITION_CHANGE,
    EventType.REWIND,
    EventType.PLAY_REQUESTED,
    EventType.PAUSED,
    EventType.PLAYING,
    EventType.EXTERNAL_RESUME_REQUESTED,
    EventType.EXTERNAL_PAUSE_REQUESTED,
    EventType.SET_CURRENT_MEDIA_INDEX,
  ];

  // Getters and setters
  bool get shallSendEvents => eventController.shallSendEvents;
  set shallSendEvents(bool value) => eventController.shallSendEvents = value;
  bool get itemsReady => _queue.itemsReady;
  bool get isShuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;
  set shuffleEnabled(bool value) => _shuffleEnabled = value;
  set repeatMode(RepeatMode value) => _repeatMode = value;
  Stream<Event> get onEvent => eventController.onEvent;

  // ================ Queue Getters ================
  Media? get currentMedia => _queue.current;
  int get previousPlaylistIndex => _queue.previousIndex;
  PreviousPlaylistPosition? get previousPlaylistPosition =>
      _queue.previousPosition;
  List<Media> get items => _queue.items;
  int get size => items.length;
  int get currentIndex => _queue.index;

  // ================ Queue Management Methods ================
  set queuePosition(int position) {
    _queue.setIndex = position;
  }

  Future<int> enqueueAll(
    List<Media> items, {
    bool autoPlay = false,
    bool saveOnTop = false,
    bool alreadyAddedToStorage = false,
  }) async {
    if (!alreadyAddedToStorage) {
      _queue.addAll(items, saveOnTop: saveOnTop);
    }

    if (_cookies == null || !_cookies!.isValid) {
      _log("Generating Cookies");
      _cookies = await cookieSigner();
    }

    String cookie = _cookies!.toHeaders();
    final int batchSize = 80;
    final List<Map<String, dynamic>> batchArgs = items.map((media) {
      final localPath = localMediaValidator?.call(media);
      return {...media.copyWith(url: localPath ?? media.url).toJson()};
    }).toList();

    for (int i = 0; i < batchArgs.length; i += batchSize) {
      final batch = batchArgs.sublist(i, min(i + batchSize, batchArgs.length));
      unawaited(
        _playerChannel.invokeMethod('enqueue', {
          'batch': batch,
          'autoPlay': autoPlay,
          'playerId': playerId,
          'shallSendEvents': shallSendEvents,
          'externalplayback': externalPlayback,
          if (i == 0) ...{'cookie': cookie},
        }),
      );
    }

    return PlayerChannel.ok;
  }

  int removeByPosition({required List<int> positionsToDelete}) {
    _playerChannel.invokeMethod('remove_in', {
      'indexesToDelete': positionsToDelete,
    });
    return _queue.removeByPosition(
      positionsToDelete: positionsToDelete,
      isShuffle: isShuffleEnabled,
    );
  }

  Future<int> removeAllMedias() async {
    _queue.clear();
    queuePosition = 0;
    await IsarService.instance.removeAllMusics();
    _playerChannel.invokeMethod('remove_all');
    return PlayerChannel.ok;
  }

  Future<int> reorder(int oldIndex, int newIndex) async {
    _queue.reorder(oldIndex, newIndex, isShuffleEnabled);
    debugPrint('#queue.reorder: ${getPositionsList()}');
    _playerChannel.invokeMethod('reorder', {
      'oldIndex': oldIndex,
      'newIndex': newIndex,
      'positionsList': getPositionsList(),
    });
    return PlayerChannel.ok;
  }

  Future<int> clear() async => removeAllMedias();

  Future<Media> restartQueue() async {
    final media = _queue.restart();
    return media;
  }

  // ================ Playback Control Methods ================
  Future<int> play() async {
    await _invokeMethodWithDefaultArgs('play');
    return PlayerChannel.ok;
  }

  Future<int> pause() async {
    _notifyPlayerStatusChangeEvent(EventType.PAUSE_REQUEST);
    return await _invokeMethodWithDefaultArgs('pause');
  }

  Future<int> stop() async {
    _notifyPlayerStatusChangeEvent(EventType.STOP_REQUESTED);
    final int result = await _invokeMethodWithDefaultArgs('stop');

    if (result == PlayerChannel.ok) {
      state = PlayerState.STOPPED;
      _notifyPlayerStatusChangeEvent(EventType.STOPPED);
    }

    return result;
  }

  Future<int> release() async {
    _notifyPlayerStatusChangeEvent(EventType.RELEASE_REQUESTED);
    final int result = await _invokeMethodWithDefaultArgs('release');

    if (result == PlayerChannel.ok) {
      state = PlayerState.STOPPED;
      _notifyPlayerStatusChangeEvent(EventType.RELEASED);
    }
    _queue.dispose();
    return result;
  }

  Future<int> seek(Duration position, {bool playWhenReady = true}) {
    _notifyPlayerStateChangeEvent(this, EventType.SEEK_START, "");
    return _invokeMethodWithDefaultArgs('seek', {
      'position': position.inMilliseconds,
      'playWhenReady': playWhenReady,
    });
  }

  Future<int> setVolume(double volume) {
    return _invokeMethodWithDefaultArgs('setVolume', {'volume': volume});
  }

  Future<int> getDuration() {
    return _invokeMethodWithDefaultArgs('getDuration');
  }

  Future<int> getCurrentPosition() async {
    return _invokeMethodWithDefaultArgs('getCurrentPosition');
  }

  // ================ Queue Navigation Methods ================
  Future<int?> previous({bool isFromChromecast = false}) async {
    if (_queue.shouldRewind()) {
      seek(Duration(milliseconds: 0));
      print("#APP LOGS ==> shouldRewind");
      return PlayerChannel.ok;
    }

    Media? media = _queue.possiblePrevious();
    if (isFromChromecast && media != null) {
      return _queue.items.indexOf(media);
    }
    if (media == null) {
      return null;
    }
    if (repeatMode == RepeatMode.REPEAT_MODE_ONE) {
      setRepeatMode("all");
    }
    return await _invokeMethodWithDefaultArgs('previous');
  }

  Future<int?> next({bool isFromChromecast = false}) async {
    final media = _queue.possibleNext(repeatMode);
    if (isFromChromecast && media != null) {
      return _queue.items.indexOf(media);
    }
    if (media != null) {
      if (repeatMode == RepeatMode.REPEAT_MODE_ONE) {
        setRepeatMode("all");
      }
      return _invokeMethodWithDefaultArgs('next');
    } else {
      return null;
    }
  }

  Future<int> forward() async {
    if (currentMedia == null) {
      return PlayerChannel.notOk;
    }
    return _forward(currentMedia);
  }

  Future<int> _forward(Media? media) async {
    if (media == null) {
      return PlayerChannel.notOk;
    }
    final duration = Duration(milliseconds: await getDuration());
    _notifyPositionChangeEvent(this, duration, duration);
    _notifyForwardEvent(media);
    return stop();
  }

  Future<int> playFromQueue(
    int pos, {
    Duration? position,
    bool loadOnly = false,
  }) async {
    if (!loadOnly) {
      _notifyPlayerStatusChangeEvent(EventType.PLAY_REQUESTED);
    }
    if (repeatMode == RepeatMode.REPEAT_MODE_ONE) {
      setRepeatMode("all");
    }
    return _playerChannel.invokeMethod('playFromQueue', {
      'position': pos,
      'timePosition': position?.inMilliseconds,
      'loadOnly': loadOnly,
    });
  }

  // ================ Repeat and Shuffle Methods ================
  Future<int> toggleRepeatMode() async {
    return _playerChannel.invokeMethod('repeat_mode');
  }

  Future<int> setRepeatMode(String mode) async {
    return _playerChannel.invokeMethod('set_repeat_mode', {'mode': mode});
  }

  Future<int> disableRepeatMode() async {
    return _playerChannel.invokeMethod('disable_repeat_mode');
  }

  Future<void> toggleShuffle() async {
    if (!isShuffleEnabled) {
      _queue.shuffle();
    } else {
      _queue.unshuffle();
    }
    debugPrint('#queue.shuffle: ${getPositionsList()}');
    _playerChannel.invokeMethod('toggle_shuffle', {
      'positionsList': getPositionsList(),
    });
  }

  // ================ Notification Methods ================
  Future<int> removeNotification() async {
    await _playerChannel.invokeMethod('remove_notification');
    return PlayerChannel.ok;
  }

  Future<int> disableNotificatonCommands() async {
    await _invokeMethodWithDefaultArgs('disable_notification_commands');
    return PlayerChannel.ok;
  }

  Future<int> enableNotificatonCommands() async {
    await _invokeMethodWithDefaultArgs('enable_notification_commands');
    return PlayerChannel.ok;
  }

  Future<int> notifyAdsPlaying() async {
    await _invokeMethodWithDefaultArgs('ads_playing');
    return PlayerChannel.ok;
  }

  // ================ Event Management Methods ================
  int enableEvents() {
    shallSendEvents = true;
    return PlayerChannel.ok;
  }

  int disableEvents() {
    shallSendEvents = false;
    return PlayerChannel.ok;
  }

  // ================ Media Management Methods ================
  Future<int> updateMediaUri({required int id, String? uri}) async {
    _playerChannel.invokeMethod('update_media_uri', {'id': id, 'uri': uri});
    return PlayerChannel.ok;
  }

  Future<int> updateFavorite({
    required bool isFavorite,
    required int id,
  }) async {
    return _playerChannel.invokeMethod('update_favorite', {
      'isFavorite': isFavorite,
      'idFavorite': id,
    });
  }

  Future<int> cast(String castId) async {
    await _playerChannel.invokeMethod('cast', {'castId': castId});
    return PlayerChannel.ok;
  }

  // ================ Queue State Methods ================
  Media? possibleNext(RepeatMode repeatMode) {
    return _queue.possibleNext(repeatMode);
  }

  Media? possiblePrevious() {
    return _queue.possiblePrevious();
  }

  void setIndexAndUpdateIsar(int index) {
    _queue.setIndex = index;
    if (currentMedia != null) {
      _queue.updateIsarIndex(currentMedia!.id, currentIndex);
    }
  }

  List<Map<String, int>> getPositionsList() {
    return [
      for (var item in _queue.playerQueue)
        {'originalPosition': item.originalPosition},
    ];
  }

  // ================ Event Notification Methods ================
  void _notifyPositionChangeEvent(
    Player player,
    Duration newPosition,
    Duration newDuration,
  ) {
    final media = _queue.current;
    final currentIndex = _queue.index;
    if (media != null) {
      final position = newPosition.inSeconds;
      eventController.add(
        PositionChangeEvent(
          media: media,
          queuePosition: currentIndex,
          position: newPosition,
          duration: newDuration,
        ),
      );
      if (position >= 0 && position % 5 == 0) {
        unawaited(
          IsarService.instance.addPreviousPlaylistPosition(
            PreviousPlaylistPosition(
              mediaId: media.id,
              position: newPosition.inMilliseconds.toDouble(),
              duration: newDuration.inMilliseconds.toDouble(),
            ),
          ),
        );
      }
    }
  }

  void _notifyPlayerStateChangeEvent(
    Player player,
    EventType eventType,
    String error,
  ) {
    final currentIndex = _queue.index;
    if (error.isNotEmpty) {
      _notifyPlayerErrorEvent(
        player: player,
        error: error,
        errorType: PlayerErrorType.INFORMATION,
      );
    }
    if (_queue.current != null) {
      eventController.add(
        Event(
          type: eventType,
          media: _queue.current!,
          queuePosition: currentIndex,
        ),
      );
    }
  }

  void _notifyPlayerErrorEvent({
    required Player player,
    required String error,
    PlayerErrorType? errorType,
  }) {
    final currentIndex = _queue.index;
    if (_queue.current != null) {
      eventController.add(
        Event(
          type: EventType.ERROR_OCCURED,
          media: _queue.current!,
          queuePosition: currentIndex,
          error: error,
          errorType: errorType ?? PlayerErrorType.UNDEFINED,
        ),
      );
    }
  }

  void _notifyForwardEvent(Media media) async {
    final positionInMilli = await getCurrentPosition();
    final durationInMilli = await getDuration();

    eventController.add(
      Event(
        type: EventType.FORWARD,
        media: media,
        queuePosition: currentIndex,
        position: Duration(milliseconds: positionInMilli),
        duration: Duration(milliseconds: durationInMilli),
      ),
    );
  }

  void _notifyPlayerStatusChangeEvent(EventType type) {
    if (currentMedia != null) {
      eventController.add(
        Event(type: type, media: currentMedia!, queuePosition: currentIndex),
      );
    }
  }

  // ================ Utility Methods ================
  void _log(String param) {
    debugPrint(param);
  }

  Future<int> _invokeMethodWithDefaultArgs(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    if (!shallSendEvents) {
      return PlayerChannel.notOk;
    }
    arguments ??= const {};
    final Map<String, dynamic> args = Map.of(arguments)
      ..['playerId'] = playerId
      ..['shallSendEvents'] = shallSendEvents
      ..['externalplayback'] = externalPlayback;

    return _playerChannel.invokeMethod(method, args);
  }

  Future<void> dispose() async {
    await eventController.dispose();
    _queue.dispose();
  }
}
