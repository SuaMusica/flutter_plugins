import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:smaws/aws.dart';
import 'package:flutter/services.dart';
import 'package:smplayer/src/before_play_event.dart';
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
  late Queue _queue;
  RepeatMode repeatMode = RepeatMode.NONE;
  final mutex = Mutex();

  final String playerId;

  final StreamController<Event> _eventStreamController =
      StreamController<Event>();

  final Future<CookiesForCustomPolicy?> Function() cookieSigner;
  final Future<String?> Function(Media)? localMediaValidator;
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

  Future<int> enqueueAll(
    List<Media> items, {
    bool shouldRemoveFirst = false,
    bool saveOnTop = false,
    bool autoPlay = false,
  }) async {
    // _queue.addAll(
    //   items,
    //   shouldRemoveFirst: shouldRemoveFirst,
    //   saveOnTop: saveOnTop,
    // );

    //ENQUEUE NO PLAYER
    // if(android)
    _cookies = await cookieSigner();
    String cookie = _cookies!.toHeaders();
    _channel
        .invokeMethod(
          'enqueue',
          items.toListJson
            ..insert(
              0,
              {
                'playerId': playerId,
                'cookie': cookie,
                'shallSendEvents': _shallSendEvents,
                'externalplayback': externalPlayback,
                'autoPlay': autoPlay,
              },
            ),
        )
        .then((result) => result ?? Future.value(Ok));
    return Ok;
  }

  int removeByPosition(
      {required List<int> positionsToDelete, required bool isShuffle}) {
    return _queue.removeByPosition(
        positionsToDelete: positionsToDelete, isShuffle: isShuffle);
  }

  Future<int> removeAll() async {
    _queue.removeAll();
    await IsarService.instance.removeAllMusics();
    return Ok;
  }

  // Future<int> removeNotificaton() async {
  //   await _invokeMethod('remove_notification');
  //   return Ok;
  // }

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

  // Future<int> sendNotification({
  //   bool? isPlaying,
  //   bool? isFavorite,
  //   Duration? position,
  //   Duration? duration,
  // }) async {
  //   if (_queue.size > 0) {
  //     if (_queue.current == null) {
  //       _queue.move(0);
  //     }
  //     final media = _queue.current!;
  //     final data = {
  //       'albumId': media.albumId.toString(),
  //       'albumTitle': media.albumTitle,
  //       'name': media.name,
  //       'author': media.author,
  //       'url': media.url,
  //       'coverUrl': media.coverUrl,
  //       'bigCoverUrl': media.bigCoverUrl,
  //       'loadOnly': false,
  //       'isLocal': media.isLocal,
  //     };

  //     if (position != null) {
  //       data['position'] = position.inMilliseconds;
  //     }

  //     if (duration != null) {
  //       data['duration'] = duration.inMilliseconds;
  //     }

  //     if (isPlaying != null) {
  //       data['isPlaying'] = isPlaying;
  //     }
  //     if (isFavorite != null) {
  //       data['isFavorite'] = isFavorite;
  //     }

  //     await _invokeMethod('send_notification', data);
  //     return Ok;
  //   } else {
  //     return Ok;
  //   }
  // }

  Future<int> disableNotificatonCommands() async {
    await _invokeMethod('disable_notification_commands');
    return Ok;
  }

  Future<int> enableNotificatonCommands() async {
    await _invokeMethod('enable_notification_commands');
    return Ok;
  }

  Future<Media> restartQueue() async {
    final media = _queue.restart();

    await this.load(media);

    return media;
  }

  Future<int> reorder(int oldIndex, int newIndex,
      [bool isShuffle = false]) async {
    _queue.reorder(oldIndex, newIndex, isShuffle);
    return Ok;
  }

  Future<int> clear() async => removeAll();

  Media? get current => _queue.current;
  set current(Media? media) {
    if (media != null) {
      _queue.replaceCurrent(media);
    }
  }

  static List<Media> newQueue = [];

  List<Media> get items => newQueue;
  int get queuePosition => _queue.index;
  int get previousPlaylistIndex => _queue.previousIndex;
  PreviousPlaylistPosition? get previousPlaylistPosition =>
      _queue.previousPosition;

  int get size => _queue.size;
  Media? get top => _queue.top;

  Future<int> load(Media media) async => _doPlay(
      // _queue.current!,
      // shouldLoadOnly: true,
      );

  Future<int> play(
    Media media, {
    double volume = 1.0,
    Duration? position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) async {
    // _queue.play(media);
    _notifyPlayerStatusChangeEvent(EventType.PLAY_REQUESTED);
    return _doPlay();
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
    // Media? media = _queue.item(pos);
    // if (media != null) {
    //   final mediaUrl = (await localMediaValidator?.call(media)) ?? media.url;
    if (!loadOnly) {
      _notifyPlayerStatusChangeEvent(EventType.PLAY_REQUESTED);
    }
    //   return _doPlay(
    //     _queue.move(pos)!,
    //     shallNotify: shallNotify,
    //     mediaUrl: mediaUrl,
    //     shouldLoadOnly: loadOnly,
    //     position: position,
    //   );
    // } else {
    //   return NotOk;
    // }
    return _channel.invokeMethod(
        'playFromQueue', {'position': pos}).then((result) => result);
    // _channel
    // .invokeMethod(
    //   'enqueue',
    //   items.toListJson
    //     ..insert(
    //       0,
    //       {
    //         'playerId': playerId,
    //         'cookie': cookie,
    //         'shallSendEvents': _shallSendEvents,
    //         'externalplayback': externalPlayback,
    //       },
    //     ),
    // )
    // .then((result) => result ?? Future.value(Ok));
  }

  Future<int> _doPlay(
      // Media media, {
      // double? volume,
      // Duration? position,
      // bool? respectSilence,
      // bool? stayAwake,
      // bool? shallNotify,
      // bool? shouldLoadOnly,
      // String? mediaUrl,
      // }
      ) async {
    // volume ??= 1.0;
    // respectSilence ??= false;
    // stayAwake ??= false;
    // shallNotify ??= false;
    // shouldLoadOnly ??= false;

    // if (shallNotify) {
    //   _notifyChangeToNext(media);
    // }
    // mediaUrl ??= (await localMediaValidator?.call(media)) ?? media.url;
    // //If it is local, check if it exists before playing it.

    // if (!mediaUrl.startsWith("http")) {
    //   if (!File(mediaUrl).existsSync() && media.fallbackUrl != null) {
    //     //Should we remove from DB??
    //     mediaUrl = media.fallbackUrl;
    //   }
    // }

    // // we need to update the value as it could have been
    // // downloading and is not downloaded
    // media.isLocal = !mediaUrl!.startsWith("http");
    // media.url = mediaUrl;
    // if (shouldLoadOnly) {
    //   debugPrint("LOADING ONLY!");
    //   return invokeLoad({
    //     'albumId': media.albumId.toString(),
    //     'albumTitle': media.albumTitle,
    //     'name': media.name,
    //     'author': media.author,
    //     'url': mediaUrl,
    //     'coverUrl': media.coverUrl,
    //     'bigCoverUrl': media.bigCoverUrl,
    //     'loadOnly': true,
    //     'isLocal': media.isLocal,
    //     'volume': volume,
    //     'position': position?.inMilliseconds,
    //     'respectSilence': respectSilence,
    //     'stayAwake': stayAwake,
    //     'isFavorite': media.isFavorite
    //   });
    // } else if (autoPlay) {
    //   _notifyBeforePlayEvent((loadOnly) => {});

    //   return invokePlay(media, {
    //     'albumId': media.albumId.toString(),
    //     'albumTitle': media.albumTitle,
    //     'name': media.name,
    //     'author': media.author,
    //     'url': mediaUrl,
    //     'coverUrl': media.coverUrl,
    //     'bigCoverUrl': media.bigCoverUrl,
    //     'loadOnly': false,
    //     'isLocal': media.isLocal,
    //     'volume': volume,
    //     'position': position?.inMilliseconds,
    //     'respectSilence': respectSilence,
    //     'stayAwake': stayAwake,
    //     'isFavorite': media.isFavorite
    //   });
    // } else {
    //   _notifyBeforePlayEvent((loadOnly) {
    //     invokePlay(media, {
    //       'albumId': media.albumId.toString(),
    //       'albumTitle': media.albumTitle,
    //       'name': media.name,
    //       'author': media.author,
    //       'url': mediaUrl,
    //       'coverUrl': media.coverUrl,
    //       'bigCoverUrl': media.bigCoverUrl,
    //       'loadOnly': loadOnly,
    //       'isLocal': media.isLocal,
    //       'volume': volume,
    //       'position': position?.inMilliseconds,
    //       'respectSilence': respectSilence,
    //       'stayAwake': stayAwake,
    //       'isFavorite': media.isFavorite
    //     });
    //   });
    _channel.invokeMethod('play');

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
    var media = _queue.rewind();
    return _rewind(media);
  }

  Future<int> _rewind(Media? media) async {
    if (media == null) {
      return NotOk;
    }
    _notifyRewind(media);
    return player.externalPlayback ? 1 : await seek(Duration(seconds: 0));
  }

  Future<int> forward() async {
    var media = _queue.current;
    if (media == null) {
      return NotOk;
    }
    return _forward(media);
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

  Future<int?> previous() async {
    Media? media = _queue.possiblePrevious();
    if (media == null) {
      return null;
    }
    final mediaUrl = (await localMediaValidator?.call(media)) ?? media.url;
    final current = _queue.current;
    var previous = _queue.previous();
    if (previous == current) {
      return _rewind(current);
    } else {
      _notifyChangeToPrevious(previous);
      return _doPlay(
          // previous,
          // mediaUrl: mediaUrl,
          );
    }
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
    final int result = await _invokeMethod('resume');

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
    _queue.dispose();
    return result;
  }

  Future<void> shuffle() async {
    _queue.shuffle();
  }

  Future<void> unshuffle() async {
    _queue.unshuffle();
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

  static Future<void> _handleOnComplete(Player player) async {
    player.state = PlayerState.COMPLETED;
    _notifyPlayerStateChangeEvent(player, EventType.FINISHED_PLAYING, "");
    switch (player.repeatMode) {
      case RepeatMode.NONE:
      case RepeatMode.QUEUE:
        player._doNext(shallNotify: false);
        break;

      case RepeatMode.TRACK:
        player.rewind();
        break;
    }
  }

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    final Map<dynamic, dynamic> callArgs = call.arguments as Map;
    _log('_platformCallHandler call ${call.method} $callArgs');
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
      case 'audio.onComplete':
        _handleOnComplete(player);
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
            _handleOnComplete(player);
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
        if (player.current != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.NEXT_NOTIFICATION,
              media: player.current!,
              queuePosition: player._queue.index,
            ),
          );
        }
        break;
      case 'commandCenter.onPrevious':
        _log("Player : Command Center : Got a previous request");
        if (player.current != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.PREVIOUS_NOTIFICATION,
              media: player.current!,
              queuePosition: player._queue.index,
            ),
          );
        }
        player.previous();
        break;
      case 'commandCenter.onPlay':
        if (player.current != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.PLAY_NOTIFICATION,
              media: player.current!,
              queuePosition: player._queue.index,
            ),
          );
        }
        break;
      case 'commandCenter.onPause':
        if (player.current != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.PAUSED_NOTIFICATION,
              media: player.current!,
              queuePosition: player._queue.index,
            ),
          );
        }
        break;
      case 'commandCenter.onTogglePlayPause':
        if (player.current != null) {
          _addUsingPlayer(
            player,
            Event(
              type: EventType.TOGGLE_PLAY_PAUSE,
              media: player.current!,
              queuePosition: player._queue.index,
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
      case 'GET_INFO':
        final queue = callArgs['QUEUE_ARGS'];
        final parsed = json.decode(queue) as List;
        final a = parsed.map((json) => Media.fromJson(json)).toList();
        _addUsingPlayer(
          player,
          Event(
            type: EventType.UPDATE_QUEUE,
            queue: a,
            queuePosition: 0,
            media: Media(
              id: 0,
              albumId: 0,
              albumTitle: "0",
              name: "0",
              ownerId: 0,
              author: "0",
              url: "0",
              isLocal: false,
              coverUrl: "0",
              bigCoverUrl: "0",
            ),
          ),
        );
        newQueue.addAll(a);
        break;
      default:
        _log('Unknown method ${call.method} ');
    }
  }

  _notifyChangeToNext(Media media) {
    _add(
        Event(type: EventType.NEXT, media: media, queuePosition: _queue.index));
  }

  _notifyChangeToPrevious(Media media) {
    _add(Event(
        type: EventType.PREVIOUS, media: media, queuePosition: _queue.index));
  }

  _notifyRewind(Media media) async {
    final positionInMilli = await getCurrentPosition();
    final durationInMilli = await getDuration();
    _add(Event(
      type: EventType.REWIND,
      media: media,
      queuePosition: _queue.index,
      position: Duration(milliseconds: positionInMilli),
      duration: Duration(milliseconds: durationInMilli),
    ));
  }

  _notifyForward(Media media) async {
    final positionInMilli = await getCurrentPosition();
    final durationInMilli = await getDuration();

    _add(Event(
      type: EventType.FORWARD,
      media: media,
      queuePosition: _queue.index,
      position: Duration(milliseconds: positionInMilli),
      duration: Duration(milliseconds: durationInMilli),
    ));
  }

  _notifyPlayerStatusChangeEvent(EventType type) {
    if (_queue.current != null) {
      _add(Event(
          type: type, media: _queue.current!, queuePosition: _queue.index));
    }
  }

  _notifyBeforePlayEvent(Function(bool) operation) {
    _add(BeforePlayEvent(
        media: _queue.current!,
        queuePosition: _queue.index,
        operation: operation));
  }

  static _notifyDurationChangeEvent(Player player, Duration newDuration) {
    if (player._queue.current != null) {
      _addUsingPlayer(
          player,
          DurationChangeEvent(
              media: player._queue.current!,
              queuePosition: player._queue.index,
              duration: newDuration));
    }
  }

  static _notifyPlayerStateChangeEvent(
    Player player,
    EventType eventType,
    String error,
  ) {
    if (error.isNotEmpty) {
      _notifyPlayerErrorEvent(
        player: player,
        error: error,
        errorType: PlayerErrorType.INFORMATION,
      );
    }
    if (player._queue.current != null) {
      _addUsingPlayer(
        player,
        Event(
          type: eventType,
          media: player._queue.current!,
          queuePosition: player._queue.index,
        ),
      );
    }
  }

  static _notifyPlayerErrorEvent({
    required Player player,
    required String error,
    PlayerErrorType? errorType,
  }) {
    if (player._queue.current != null) {
      _addUsingPlayer(
        player,
        Event(
          type: EventType.ERROR_OCCURED,
          media: player._queue.current!,
          queuePosition: player._queue.index,
          error: error,
          errorType: errorType ?? PlayerErrorType.UNDEFINED,
        ),
      );
    }
  }

  static _notifyPositionChangeEvent(
      Player player, Duration newPosition, Duration newDuration) {
    final media = player.current;
    if (media != null) {
      final position = newPosition.inSeconds;
      _addUsingPlayer(
        player,
        PositionChangeEvent(
          media: media,
          queuePosition: player.queuePosition,
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
