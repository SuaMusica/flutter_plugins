import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:smaws/aws.dart';
import 'package:flutter/services.dart';
import 'package:smplayer/src/before_play_event.dart';
import 'package:smplayer/src/event.dart';
import 'package:smplayer/src/event_type.dart';
import 'package:smplayer/src/media.dart';
import 'package:smplayer/src/duration_change_event.dart';
import 'package:smplayer/src/position_change_event.dart';
import 'package:smplayer/src/queue.dart';
import 'package:smplayer/src/repeat_mode.dart';
import 'package:mutex/mutex.dart';

import 'player_state.dart';

class Player {
  static const Ok = 1;
  static const NotOk = -1;
  static final MethodChannel _channel = const MethodChannel('smplayer')
    ..setMethodCallHandler(platformCallHandler);

  static Player player;
  static bool logEnabled = false;

  bool _shallSendEvents = true;
  bool externalPlayback = false;
  CookiesForCustomPolicy _cookies;
  PlayerState state = PlayerState.IDLE;
  Queue _queue = Queue();
  RepeatMode repeatMode = RepeatMode.NONE;
  final mutex = Mutex();

  final String playerId;

  final StreamController<Event> _eventStreamController =
      StreamController<Event>();

  final Future<CookiesForCustomPolicy> Function() cookieSigner;
  final Future<String> Function(Media) localMediaValidator;
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

  Stream<Event> _stream;

  Stream<Event> get onEvent {
    if (_stream == null) {
      _stream = _eventStreamController.stream.asBroadcastStream();
    }
    return _stream;
  }

  Player({
    @required this.playerId,
    @required this.cookieSigner,
    @required this.localMediaValidator,
    this.autoPlay = false,
  }) {
    player = this;
  }

  Future<int> _invokeMethod(
    String method, [
    Map<String, dynamic> arguments,
  ]) async {
    arguments ??= const {};
    if (_cookies == null || !_cookies.isValid) {
      _log("Generating Cookies");
      _cookies = await cookieSigner();
    }
    String cookie = _cookies.toHeaders();
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
        .then((result) => (result as int));
  }

  Future<int> enqueue(
    Media media, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) async {
    _queue.add(media);
    return Ok;
  }

  Future<int> enqueueAll(
    List<Media> items, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) async {
    _queue.addAll(items);
    return Ok;
  }

  Future<int> remove(Media media) async {
    _queue.remove(media);
    return Ok;
  }

  Future<int> removeAll() async {
    _queue.removeAll();
    return Ok;
  }

  Future<int> removeNotificaton() async {
    await _invokeMethod('remove_notification');
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

  Future<int> sendNotification({
    bool isPlaying,
    Duration position,
    Duration duration,
  }) async {
    if (_queue.size > 0) {
      if (_queue.current == null) {
        _queue.move(0);
      }
      final media = _queue.current;
      final data = {
        'albumId': media.albumId?.toString() ?? "0",
        'albumTitle': media.albumTitle ?? "",
        'name': media.name,
        'author': media.author,
        'url': media.url,
        'coverUrl': media.coverUrl,
        'loadOnly': false,
        'isLocal': media.isLocal,
      };

      if (position != null) {
        data['position'] = position.inMilliseconds;
      }

      if (duration != null) {
        data['duration'] = duration.inMilliseconds;
      }

      if (isPlaying != null) {
        data['isPlaying'] = isPlaying;
      }
      await _invokeMethod('send_notification', data);
      return Ok;
    } else {
      return Ok;
    }
  }

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

  Media get current => _queue.current;
  List<Media> get items => _queue.items;
  int get queuePosition => _queue.index;
  int get size => _queue.size;
  Media get top => _queue.top;

  Future<int> load(Media media) async => _doPlay(
        _queue.current,
        shouldLoadOnly: true,
      );

  Future<int> play(
    Media media, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) async {
    _queue.play(media);
    _notifyPlayerStatusChangeEvent(EventType.PLAY_REQUESTED);
    return _doPlay(_queue.current);
  }

  Future<int> playFromQueue(
    int pos, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
    bool shallNotify = false,
    bool loadOnly = false,
  }) async {
    Media media = _queue.item(pos);
    if (media != null) {
      final mediaUrl = (await localMediaValidator(media)) ?? media.url;
      if (!loadOnly) {
        _notifyPlayerStatusChangeEvent(EventType.PLAY_REQUESTED);
      }
      return _doPlay(
        _queue.move(pos),
        shallNotify: shallNotify,
        mediaUrl: mediaUrl,
        shouldLoadOnly: loadOnly,
        position: position,
      );
    } else {
      return NotOk;
    }
  }

  Future<int> _doPlay(
    Media media, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
    bool shallNotify = false,
    bool shouldLoadOnly = false,
    String mediaUrl,
  }) async {
    if (shallNotify) {
      _notifyChangeToNext(media);
    }
    mediaUrl ??= (await localMediaValidator(media)) ?? media.url;
    //If it is local, check if it exists before playing it.

    if (!mediaUrl.startsWith("http")) {
      if (!File(mediaUrl).existsSync() && media.fallbackUrl != null) {
        //Should we remove from DB??
        mediaUrl = media.fallbackUrl;
      }
    }
    volume ??= 1.0;
    respectSilence ??= false;
    stayAwake ??= false;

    // we need to update the value as it could have been
    // downloading and is not downloaded
    media.isLocal = !mediaUrl.startsWith("http");
    media.url = mediaUrl;
    if (shouldLoadOnly) {
      debugPrint("LOADING ONLY!");
      return invokeLoad({
        'albumId': media.albumId?.toString() ?? "0",
        'albumTitle': media.albumTitle ?? "",
        'name': media.name,
        'author': media.author,
        'url': mediaUrl,
        'coverUrl': media.coverUrl,
        'loadOnly': true,
        'isLocal': media.isLocal,
        'volume': volume,
        'position': position?.inMilliseconds,
        'respectSilence': respectSilence,
        'stayAwake': stayAwake,
      });
    } else if (autoPlay) {
      _notifyBeforePlayEvent((loadOnly) => {});

      return invokePlay(media, {
        'albumId': media.albumId?.toString() ?? "0",
        'albumTitle': media.albumTitle ?? "",
        'name': media.name,
        'author': media.author,
        'url': mediaUrl,
        'coverUrl': media.coverUrl,
        'loadOnly': false,
        'isLocal': media.isLocal,
        'volume': volume,
        'position': position?.inMilliseconds,
        'respectSilence': respectSilence,
        'stayAwake': stayAwake,
      });
    } else {
      _notifyBeforePlayEvent((loadOnly) {
        invokePlay(media, {
          'albumId': media.albumId.toString() ?? "0",
          'albumTitle': media.albumTitle ?? "",
          'name': media.name,
          'author': media.author,
          'url': mediaUrl,
          'coverUrl': media.coverUrl,
          'loadOnly': loadOnly,
          'isLocal': media.isLocal,
          'volume': volume,
          'position': position?.inMilliseconds,
          'respectSilence': respectSilence,
          'stayAwake': stayAwake,
        });
      });

      return Ok;
    }
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

  Future<int> _rewind(Media media) async {
    if (media == null) {
      return NotOk;
    }
    _notifyRewind(media);
    return player.externalPlayback ? 1 : seek(Duration(seconds: 0));
  }

  Future<int> forward() async {
    var media = _queue.current;
    return _forward(media);
  }

  Future<int> _forward(Media media) async {
    if (media == null) {
      return NotOk;
    }
    final duration = Duration(milliseconds: await getDuration());
    _notifyPositionChangeEvent(this, duration, duration);
    _notifyForward(media);
    return stop();
  }

  Future<int> previous() async {
    Media media = _queue.possiblePrevious();
    if (media != null) {
      final mediaUrl = (await localMediaValidator(media)) ?? media.url;
      final current = _queue.current;
      var previous = _queue.previous();
      if (previous == null) {
        return NotOk;
      }

      if (previous == current) {
        return _rewind(current);
      } else {
        _notifyChangeToPrevious(previous);
        return _doPlay(
          previous,
          mediaUrl: mediaUrl,
        );
      }
    } else {
      return NotOk;
    }
  }

  Future<int> next({
    bool shallNotify = true,
  }) async {
    final media = _queue.possibleNext(repeatMode);
    if (media != null) {
      final mediaUrl = (await localMediaValidator(media)) ?? media.url;

      return _doNext(
        shallNotify: shallNotify,
        mediaUrl: mediaUrl,
      );
    } else {
      return null;
    }
  }

  Future<int> _doNext({
    bool shallNotify,
    String mediaUrl,
  }) async {
    final current = _queue.current;
    Media next;

    // first case, nothing has yet played
    // therefore, we need to play the first
    // track on the key and treat this as a
    // play method invocation
    if (current == null) {
      next = _queue.next();
      if (next == null) {
        // nothing to play
        return NotOk;
      }
      // notice that in this case
      // we do not emit the NEXT event
      // we only play the track
      return _doPlay(
        next,
        shallNotify: shallNotify,
      );
    }

    next = _queue.next();
    if (next == null) {
      if (current == null) {
        return NotOk;
      }

      if ((state == PlayerState.PLAYING || state == PlayerState.PAUSED) &&
          repeatMode == RepeatMode.NONE) {
        return _forward(current);
      } else {
        if (repeatMode == RepeatMode.NONE) {
          _queue.index = -1;
          return NotOk;
        } else if (repeatMode == RepeatMode.QUEUE) {
          next = _queue.restart();
        } else if (repeatMode == RepeatMode.TRACK) {
          repeatMode = RepeatMode.QUEUE;
          next = _queue.restart();
        } else {
          // this should not happen!
          return NotOk;
        }
      }
    }
    if (repeatMode == RepeatMode.TRACK) {
      repeatMode = RepeatMode.QUEUE;
    }
    return _doPlay(
      next,
      shallNotify: shallNotify,
      mediaUrl: mediaUrl,
    );
  }

  Future<int> pause() async {
    _notifyPlayerStatusChangeEvent(EventType.PAUSE_REQUEST);

    return await _invokeMethod('pause');
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

    if (player == null) {
      return;
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
      case 'audio.onComplete':
        _handleOnComplete(player);
        break;
      case 'audio.onError':
        player.state = PlayerState.ERROR;
        final errorType = callArgs['errorType'] ?? 2;

        _notifyPlayerErrorEvent(
          player,
          'error',
          PlayerErrorType.values[errorType],
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
            final error = callArgs['error'] as String;
            _notifyPlayerErrorEvent(player, error);
            break;
        }

        break;
      case 'commandCenter.onNext':
        _log("Player : Command Center : Got a next request");
        player.next();
        break;
      case 'commandCenter.onPrevious':
        _log("Player : Command Center : Got a previous request");
        player.previous();
        break;
      case 'externalPlayback.play':
        print("Player: externalPlayback : Play");
        _notifyPlayerStateChangeEvent(
            player, EventType.EXTERNAL_RESUME_REQUESTED, "");
        break;
      case 'externalPlayback.pause':
        print("Player: externalPlayback : Pause");
        _notifyPlayerStateChangeEvent(
            player, EventType.EXTERNAL_PAUSE_REQUESTED, "");
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
    _add(Event(type: type, media: _queue.current, queuePosition: _queue.index));
  }

  _notifyBeforePlayEvent(Function(bool) operation) {
    _add(BeforePlayEvent(
        media: _queue.current,
        queuePosition: _queue.index,
        operation: operation));
  }

  static _notifyDurationChangeEvent(Player player, Duration newDuration) {
    _addUsingPlayer(
        player,
        DurationChangeEvent(
            media: player._queue.current,
            queuePosition: player._queue.index,
            duration: newDuration));
  }

  static _notifyPlayerStateChangeEvent(
    Player player,
    EventType eventType,
    String error,
  ) {
    if (error.isNotEmpty) {
      _notifyPlayerErrorEvent(
        player,
        error,
        PlayerErrorType.INFORMATION,
      );
    }
    _addUsingPlayer(
      player,
      Event(
        type: eventType,
        media: player._queue.current,
        queuePosition: player._queue.index,
      ),
    );
  }

  static _notifyPlayerErrorEvent(Player player, String error,
      [PlayerErrorType errorType = PlayerErrorType.UNDEFINED]) {
    _addUsingPlayer(
      player,
      Event(
        type: EventType.ERROR_OCCURED,
        media: player._queue.current,
        queuePosition: player._queue.index,
        error: error,
        errorType: errorType,
      ),
    );
  }

  static _notifyPositionChangeEvent(
      Player player, Duration newPosition, Duration newDuration) {
    _addUsingPlayer(
      player,
      PositionChangeEvent(
          media: player._queue.current,
          queuePosition: player._queue.index,
          position: newPosition,
          duration: newDuration),
    );
  }

  static void _log(String param) {
    debugPrint(param);
  }

  void _add(Event event) {
    if (_eventStreamController != null &&
        !_eventStreamController.isClosed &&
        (_shallSendEvents || chromeCastEnabledEvents.contains(event.type))) {
      _eventStreamController.add(event);
    }
  }

  static void _addUsingPlayer(Player player, Event event) {
    if (event.type != EventType.POSITION_CHANGE) {
      debugPrint("_platformCallHandler _addUsingPlayer $event");
    }
    if (player._eventStreamController != null &&
        !player._eventStreamController.isClosed &&
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
