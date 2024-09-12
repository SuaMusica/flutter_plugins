import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:smaws/aws.dart';
import 'package:flutter/services.dart';
import 'package:smplayer/src/event.dart';
import 'package:smplayer/src/event_type.dart';
import 'package:smplayer/src/isar_service.dart';
import 'package:smplayer/src/media.dart';
import 'package:smplayer/src/duration_change_event.dart';
import 'package:smplayer/src/position_change_event.dart';
import 'package:smplayer/src/previous_playlist_model.dart';
import 'package:smplayer/src/queue.dart';
import 'package:smplayer/src/repeat_mode.dart';
import 'package:mutex/mutex.dart';

import 'player_state.dart';

class Player {
  Player({
    required this.playerId,
    required this.cookieSigner,
    required this.localMediaValidator,
    this.initializeIsar = false,
    this.autoPlay = false,
  }) {
    _queue = Queue(initializeIsar: this.initializeIsar);
    player = this;
  }
  static const Ok = 1;
  static const NotOk = -1;
  static const CHANNEL = 'suamusica.com.br/player';
  static final MethodChannel _channel = const MethodChannel(CHANNEL)
    ..setMethodCallHandler(platformCallHandler);

  static late Player player;
  static bool logEnabled = false;

  bool _shallSendEvents = true;
  bool initializeIsar;
  bool externalPlayback = false;
  bool get itemsReady => _queue.itemsReady;

  CookiesForCustomPolicy? _cookies;
  PlayerState state = PlayerState.IDLE;
  static late Queue _queue;
  static RepeatMode _repeatMode = RepeatMode.REPEAT_MODE_OFF;
  static bool _shuffleEnabled = false;
  static int _idSum = 0;
  final mutex = Mutex();

  final String playerId;

  int get idSum => _idSum;
  bool get isShuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;

  set setShuffleEnabled(bool value) => _shuffleEnabled = value;
  set repeatMode(RepeatMode value) => _repeatMode = value;

  final StreamController<Event> _eventStreamController =
      StreamController<Event>();

  final Future<CookiesForCustomPolicy?> Function() cookieSigner;
  final String? Function(Media)? localMediaValidator;
  final bool autoPlay;
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
    EventType.EXTERNAL_PAUSE_REQUESTED
  ];

  Stream<Event>? _stream;

  Stream<Event> get onEvent {
    _stream ??= _eventStreamController.stream.asBroadcastStream();
    return _stream!;
  }

  Future<int> _invokeMethod(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    arguments ??= const {};
    if (_cookies == null || !_cookies!.isValid) {
      _log("Generating Cookies");
      _cookies = await cookieSigner();
    }
    String cookie = _cookies!.toHeaders();
    if (method == "play") {
      _log("Cookie: $cookie");
    }

    final Map<String, dynamic> args = Map.of(arguments)
      ..['playerId'] = playerId
      ..['cookie'] = cookie
      ..['shallSendEvents'] = _shallSendEvents
      ..['externalplayback'] = externalPlayback;

    return _channel
        .invokeMethod(method, args)
        .then((result) => result ?? Future.value(Ok));
  }

  Future<int> enqueue({
    required Media media,
    bool autoPlay = false,
  }) async {
    enqueueAll(
      [media],
      autoPlay: autoPlay,
    );
    return Ok;
  }

  set setQueuePosition(int position) {
    _queue.setIndex = position;
  }

  Future<int> enqueueAll(
    List<Media> items, {
    bool shouldRemoveFirst = false,
    bool saveOnTop = false,
    bool autoPlay = false,
    // Future<String?> Function(
    //   int albumId,
    //   String url,
    // )? getLocalCover,
  }) async {
    _cookies = await cookieSigner();
    String cookie = _cookies!.toHeaders();
    final int batchSize = 80;

    final List<Map<String, dynamic>> batchArgs = items
        .map(
          (media) => {
            ...media
                .copyWith(
                  url: localMediaValidator?.call(media) ?? media.url,
                )
                .toJson(),
          },
        )
        .toList();
    int j = 0;
    for (int i = 0; i < batchArgs.length; i += batchSize) {
      final batch = batchArgs.sublist(i, min(i + batchSize, batchArgs.length));
      final bool isLastBatch = (items.length / batchSize).ceil() == ++j;
      debugPrint(
          '##enqueueAll $isLastBatch | ${(items.length / batchSize).ceil()} | $j');
      unawaited(
        _channel.invokeMethod(
          'enqueue',
          {
            'batch': batch,
            'isLastBatch': isLastBatch,
            'autoPlay': autoPlay,
            'playerId': playerId,
            'shallSendEvents': _shallSendEvents,
            'externalplayback': externalPlayback,
            if (i == 0) ...{
              'cookie': cookie,
            },
          },
        ),
      );
    }

    await IsarService.instance.removeAllMusics();
    _queue.addAll(items);
    return Ok;
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

  int removeByPosition({
    required List<int> positionsToDelete,
  }) {
    _channel.invokeMethod('remove_in', {'indexesToDelete': positionsToDelete});

    return _queue.removeByPosition(
      positionsToDelete: positionsToDelete,
      isShuffle: isShuffleEnabled,
    );
  }

  Future<int> removeAll() async {
    _queue.clear();
    setQueuePosition = 0;
    await IsarService.instance.removeAllMusics();
    _channel.invokeMethod('remove_all');
    return Ok;
  }

  Future<int> adsPlaying() async {
    await _invokeMethod('ads_playing');
    return Ok;
  }

  int enableEvents() {
    this._shallSendEvents = true;
    return Ok;
  }

  int disableEvents() {
    this._shallSendEvents = false;
    return Ok;
  }

  Future<Media> restartQueue() async {
    final media = _queue.restart();
    return media;
  }

  Future<int> reorder(
    int oldIndex,
    int newIndex,
  ) async {
    _queue.reorder(oldIndex, newIndex, isShuffleEnabled);
    debugPrint('#_queue.reorder: ${getPositionsList()}');
    _channel.invokeMethod('reorder', {
      'oldIndex': oldIndex,
      'newIndex': newIndex,
      'positionsList': getPositionsList(),
    });
    return Ok;
  }

  Future<int> clear() async => removeAll();

  Media? get currentMedia => _queue.current;

  int get previousPlaylistIndex => _queue.previousIndex;
  PreviousPlaylistPosition? get previousPlaylistPosition =>
      _queue.previousPosition;

  List<Media> get items => _queue.items;
  List<Media> get isarItems => _queue.storage.map((e) => e.item).toList();
  int get size => items.length;

  int get currentIndex => _queue.index;

  Future<int> play({bool shouldPrepare = false}) async {
    _notifyPlayerStatusChangeEvent(EventType.PLAY_REQUESTED);
    return _doPlay(shouldPrepare: shouldPrepare);
  }

  Future<int> playFromQueue(
    int pos, {
    double volume = 1.0,
    Duration? position,
    bool respectSilence = false,
    bool stayAwake = false,
    bool shallNotify = false,
    bool loadOnly = false,
  }) async {
    if (!loadOnly) {
      _notifyPlayerStatusChangeEvent(EventType.PLAY_REQUESTED);
    }
    return _channel.invokeMethod(
        'playFromQueue', {'position': pos}).then((result) => result);
  }

  Future<int> _doPlay({
    bool shouldPrepare = false,
  }) async {
    // _notifyBeforePlayEvent(
    //   (_) =>
    _channel.invokeMethod(
      'play',
      {'shouldPrepare': shouldPrepare},
      // ),
    );
    return Ok;
  }

  Future<int> invokePlay(Media media, Map<String, dynamic> args) async {
    print(args);
    final int result = await _invokeMethod('play', args);
    return result;
  }

  Future<int> invokeLoad(Map<String, dynamic> args) async {
    final int result = await _invokeMethod('load', args);
    return result;
  }

  Future<int> rewind() async {
    final media = _queue.rewind();
    _notifyRewind(media);
    return Ok;
  }

  List<Map<String, int>> getPositionsList() {
    return [
      for (var item in _queue.storage)
        {
          'originalPosition': item.originalPosition,
        }
    ];
  }

  Future<int> forward() async {
    if (currentMedia == null) {
      return NotOk;
    }
    return _forward(currentMedia);
  }

  Future<int> _forward(Media? media) async {
    if (media == null) {
      return NotOk;
    }
    final duration = Duration(milliseconds: await getDuration());
    _notifyPositionChangeEvent(this, duration, duration);
    _notifyForward(media);
    return stop();
  }

  Future<int> toggleRepeatMode() async {
    return _channel.invokeMethod('repeat_mode').then((result) => result);
  }

  Future<int> disableRepeatMode() async {
    return _channel
        .invokeMethod('disable_repeat_mode')
        .then((result) => result);
  }

  Future<int?> previous() async {
    Media? media = _queue.possibleNext(repeatMode);
    if (media == null) {
      return null;
    }
    // final mediaUrl = (await localMediaValidator?.call(media)) ?? media.url;
    _channel.invokeMethod('previous').then((result) => result);
    return Ok;
  }

  Future<int?> next({
    bool shallNotify = true,
  }) async {
    final media = _queue.possibleNext(repeatMode);
    if (media != null) {
      final mediaUrl = (await localMediaValidator?.call(media)) ?? media.url;

      return _doNext(
        shallNotify: shallNotify,
        mediaUrl: mediaUrl,
      );
    } else {
      return null;
    }
  }

  Future<int> _doNext({
    bool? shallNotify,
    String? mediaUrl,
  }) async {
    return _channel.invokeMethod('next').then((result) => result);
  }

  Future<int> updateFavorite({
    required bool isFavorite,
    required int id,
  }) async {
    return _channel.invokeMethod('update_favorite', {
      'isFavorite': isFavorite,
      'idFavorite': id,
    }).then((result) => result);
  }

  Future<int> pause() async {
    _notifyPlayerStatusChangeEvent(EventType.PAUSE_REQUEST);

    // return await _invokeMethod('pause');
    return _channel.invokeMethod('pause').then((result) => result);
  }

  void addUsingPlayer(Event event) => _addUsingPlayer(player, event);

  Future<int> stop() async {
    _notifyPlayerStatusChangeEvent(EventType.STOP_REQUESTED);
    final int result = await _invokeMethod('stop');

    if (result == Ok) {
      state = PlayerState.STOPPED;
      _notifyPlayerStatusChangeEvent(EventType.STOPPED);
    }

    return result;
  }

  Future<int> resume() async {
    _notifyPlayerStatusChangeEvent(EventType.RESUME_REQUESTED);
    final int result = await _invokeMethod('play');

    if (result == Ok) {
      _notifyPlayerStatusChangeEvent(EventType.RESUMED);
    }

    return result;
  }

  Future<int> release() async {
    _notifyPlayerStatusChangeEvent(EventType.RELEASE_REQUESTED);
    final int result = await _invokeMethod('release');

    if (result == Ok) {
      state = PlayerState.STOPPED;
      _notifyPlayerStatusChangeEvent(EventType.RELEASED);
    }
    // _queue.dispose();
    return result;
  }

  Future<void> toggleShuffle() async {
    if (!isShuffleEnabled) {
      _queue.shuffle();
    } else {
      _queue.unshuffle();
    }
    debugPrint('#_queue.shuffle: ${getPositionsList()}');
    _channel
        .invokeMethod('toggle_shuffle', {'positionsList': getPositionsList()});
  }

  Future<int> seek(Duration position) {
    _notifyPlayerStateChangeEvent(this, EventType.SEEK_START, "");
    return _invokeMethod('seek', {'position': position.inMilliseconds});
  }

  Future<int> setVolume(double volume) {
    return _invokeMethod('setVolume', {'volume': volume});
  }

  Future<int> getDuration() {
    return _invokeMethod('getDuration');
  }

  Future<int> getCurrentPosition() async {
    return _invokeMethod('getCurrentPosition');
  }

  static Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      _log('Unexpected error: $ex');
    }
  }

  // static Future<void> _handleOnComplete(Player player) async {
  //   player.state = PlayerState.COMPLETED;
  //   _notifyPlayerStateChangeEvent(player, EventType.FINISHED_PLAYING, "");
  //   switch (player.repeatMode) {
  //     case RepeatMode.REPEAT_MODE_OFF:
  //     case RepeatMode.REPEAT_MODE_ALL:
  //       player._doNext(shallNotify: false);
  //       break;

  //     case RepeatMode.REPEAT_MODE_ONE:
  //       player.rewind();
  //       break;
  //   }
  // }

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    final currentMedia = _queue.current;
    final currentIndex = _queue.index;
    final Map<dynamic, dynamic> callArgs = call.arguments as Map;
    if (call.method != 'audio.onCurrentPosition') {
      _log('_platformCallHandler call ${call.method} $callArgs');
    }
    switch (call.method) {
      case 'audio.onDuration':
        final duration = callArgs['duration'];
        if (duration > 0) {
          Duration newDuration = Duration(milliseconds: duration);
          _notifyDurationChangeEvent(player, newDuration);
        }
        break;
      case 'audio.onCurrentPosition':
        final position = callArgs['position'];
        Duration newPosition = Duration(milliseconds: position);
        final duration = callArgs['duration'];
        Duration newDuration = Duration(milliseconds: duration);
        _notifyPositionChangeEvent(player, newPosition, newDuration);
        break;
      case 'audio.onError':
        player.state = PlayerState.ERROR;
        final errorType = callArgs['errorType'] ?? 2;

        _notifyPlayerErrorEvent(
          player: player,
          error: 'error',
          errorType: PlayerErrorType.values[errorType],
        );
        break;
      case 'state.change':
        final state = callArgs['state'];
        String error = callArgs['error'] ?? "";
        _log('state.change call ${PlayerState.values[state]}');
        player.state = PlayerState.values[state];
        switch (player.state) {
          case PlayerState.IDLE:
            break;
          case PlayerState.BUFFERING:
            _notifyPlayerStateChangeEvent(
              player,
              EventType.BUFFERING,
              error,
            );
            break;
          case PlayerState.ITEM_TRANSITION:
            _notifyPlayerStateChangeEvent(
              player,
              EventType.BEFORE_PLAY,
              error,
            );
            break;
          case PlayerState.PLAYING:
            _notifyPlayerStateChangeEvent(
              player,
              EventType.PLAYING,
              error,
            );
            break;
          case PlayerState.PAUSED:
            _notifyPlayerStateChangeEvent(
              player,
              EventType.PAUSED,
              error,
            );
            break;

          case PlayerState.STOPPED:
            _notifyPlayerStateChangeEvent(
              player,
              EventType.STOP_REQUESTED,
              error,
            );
            break;

          case PlayerState.SEEK_END:
            _notifyPlayerStateChangeEvent(
              player,
              EventType.SEEK_END,
              error,
            );
            break;

          case PlayerState.BUFFER_EMPTY:
            _notifyPlayerStateChangeEvent(
              player,
              EventType.BUFFER_EMPTY,
              error,
            );
            break;

          case PlayerState.COMPLETED:
            // _handleOnComplete(player);
            break;

          case PlayerState.ERROR:
            final error = callArgs['error'] ?? "Unknown from Source";
            final isPermissionError =
                (error as String).contains('Permission denied');
            _notifyPlayerErrorEvent(
                player: player,
                error: error,
                errorType: isPermissionError
                    ? PlayerErrorType.PERMISSION_DENIED
                    : null);
            break;
        }

        break;
      case 'commandCenter.onNext':
        _log("Player : Command Center : Got a next request");
        player.next();
        if (currentMedia != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.NEXT_NOTIFICATION,
              media: currentMedia,
              queuePosition: currentIndex,
            ),
          );
        }
        break;
      case 'commandCenter.onPrevious':
        _log("Player : Command Center : Got a previous request");
        if (currentMedia != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.PREVIOUS_NOTIFICATION,
              media: currentMedia,
              queuePosition: currentIndex,
            ),
          );
        }
        player.previous();
        break;
      case 'commandCenter.onPlay':
        if (currentMedia != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.PLAY_NOTIFICATION,
              media: currentMedia,
              queuePosition: currentIndex,
            ),
          );
        }
        break;
      case 'commandCenter.onPause':
        if (currentMedia != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.PAUSED_NOTIFICATION,
              media: currentMedia,
              queuePosition: currentIndex,
            ),
          );
        }
        break;
      case 'commandCenter.onTogglePlayPause':
        if (currentMedia != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.TOGGLE_PLAY_PAUSE,
              media: currentMedia,
              queuePosition: currentIndex,
            ),
          );
        }
        break;
      case 'externalPlayback.play':
        print("Player: externalPlayback : Play");
        _notifyPlayerStateChangeEvent(
            player, EventType.EXTERNAL_RESUME_REQUESTED, "");
        break;
      case 'externalPlayback.pause':
        print("Player: externalPlayback : Pause");
        _notifyPlayerStateChangeEvent(
          player,
          EventType.EXTERNAL_PAUSE_REQUESTED,
          "",
        );
        break;
      case 'commandCenter.onFavorite':
        final favorite = callArgs['favorite'];
        print("Player: onFavorite : $favorite");
        _notifyPlayerStateChangeEvent(
          player,
          favorite ? EventType.FAVORITE_MUSIC : EventType.UNFAVORITE_MUSIC,
          "",
        );

        break;
      case 'SET_CURRENT_MEDIA_INDEX':
        _queue.setIndex = callArgs['CURRENT_MEDIA_INDEX'];
        _notifyPlayerStateChangeEvent(
          player,
          EventType.SET_CURRENT_MEDIA_INDEX,
          "",
        );
        break;
      case 'REPEAT_CHANGED':
        _repeatMode = RepeatMode.values[callArgs['REPEAT_MODE']];
        _notifyPlayerStateChangeEvent(
          player,
          EventType.REPEAT_CHANGED,
          "",
        );
        break;
      case 'SHUFFLE_CHANGED':
        _shuffleEnabled = callArgs['SHUFFLE_MODE'];
        _notifyPlayerStateChangeEvent(
          player,
          EventType.SHUFFLE_CHANGED,
          "",
        );
        break;
      case 'GET_INFO':
        _idSum = callArgs['ID_SUM'];
        _notifyPlayerStateChangeEvent(
          player,
          EventType.UPDATE_QUEUE,
          "",
        );
        break;
      default:
        _log('Unknown method ${call.method} ');
    }
  }

  _notifyRewind(Media media) async {
    final positionInMilli = await getCurrentPosition();
    final durationInMilli = await getDuration();
    _add(
      Event(
        type: EventType.REWIND,
        media: media,
        queuePosition: currentIndex,
        position: Duration(milliseconds: positionInMilli),
        duration: Duration(milliseconds: durationInMilli),
      ),
    );
  }

  _notifyForward(Media media) async {
    final positionInMilli = await getCurrentPosition();
    final durationInMilli = await getDuration();

    _add(Event(
      type: EventType.FORWARD,
      media: media,
      queuePosition: currentIndex,
      position: Duration(milliseconds: positionInMilli),
      duration: Duration(milliseconds: durationInMilli),
    ));
  }

  _notifyPlayerStatusChangeEvent(EventType type) {
    if (currentMedia != null) {
      _add(
        Event(
          type: type,
          media: currentMedia!,
          queuePosition: currentIndex,
        ),
      );
    }
  }

  static _notifyDurationChangeEvent(Player player, Duration newDuration) {
    final currentIndex = _queue.index;
    if (_queue.current != null) {
      _addUsingPlayer(
          player,
          DurationChangeEvent(
              media: _queue.current!,
              queuePosition: currentIndex,
              duration: newDuration));
    }
  }

  static _notifyPlayerStateChangeEvent(
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
      _addUsingPlayer(
        player,
        Event(
          type: eventType,
          media: _queue.current!,
          queuePosition: currentIndex,
        ),
      );
    }
  }

  static _notifyPlayerErrorEvent({
    required Player player,
    required String error,
    PlayerErrorType? errorType,
  }) {
    final currentIndex = _queue.index;
    if (_queue.current != null) {
      _addUsingPlayer(
        player,
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

  static _notifyPositionChangeEvent(
      Player player, Duration newPosition, Duration newDuration) {
    final media = _queue.current;
    final currentIndex = _queue.index;
    if (media != null) {
      final position = newPosition.inSeconds;
      _addUsingPlayer(
        player,
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

  static void _log(String param) {
    debugPrint(param);
  }

  void _add(Event event) {
    if (!_eventStreamController.isClosed &&
        (_shallSendEvents || chromeCastEnabledEvents.contains(event.type))) {
      _eventStreamController.add(event);
    }
  }

  static void _addUsingPlayer(Player player, Event event) {
    if (event.type != EventType.POSITION_CHANGE) {
      debugPrint("_platformCallHandler _addUsingPlayer $event");
    }
    if (!player._eventStreamController.isClosed &&
        (player._shallSendEvents ||
            player.chromeCastEnabledEvents.contains(event.type))) {
      player._eventStreamController.add(event);
    }
  }

  Future<void> dispose() async {
    List<Future> futures = [];
    if (!_eventStreamController.isClosed) {
      futures.add(_eventStreamController.close());
    }
    await Future.wait(futures);
  }
}
