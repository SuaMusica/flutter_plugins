import 'dart:async';

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
import 'package:uuid/uuid.dart';

import 'player_state.dart';

class Player {
  static const Ok = 1;
  static const NotOk = -1;
  static final MethodChannel _channel = const MethodChannel('suamusica_player')
    ..setMethodCallHandler(platformCallHandler);

  static final players = Map<String, Player>();
  static bool logEnabled = false;

  final _uuid = Uuid();
  CookiesForCustomPolicy _cookies;
  PlayerState state = PlayerState.IDLE;
  Queue _queue = Queue();
  RepeatMode repeatMode = RepeatMode.NONE;

  final StreamController<Event> _eventStreamController =
      StreamController<Event>();

  final Future<CookiesForCustomPolicy> Function() cookieSigner;

  Stream<Event> _stream;

  Stream<Event> get onEvent {
    if (_stream == null) {
      _stream = _eventStreamController.stream.asBroadcastStream();
    }
    return _stream;
  }

  String playerId;
  bool autoPlay;

  Player({
    this.cookieSigner,
    this.autoPlay = false,
  }) {
    playerId = _uuid.v4();
    players[playerId] = this;
  }

  Future<int> _invokeMethod(
    String method, [
    Map<String, dynamic> arguments,
  ]) async {
    arguments ??= const {};

    Future<bool> requiresCookie = Future.value(method == 'play');
    return requiresCookie.then((requires) {
      Future<CookiesForCustomPolicy> cookies = Future.value(_cookies);
      if (requires) {
        if (_cookies == null || !_cookies.isValid()) {
          cookies = (() async => await cookieSigner())();
        }
      }

      return cookies.then((cookies) {
        String cookie = "";
        // we need to save it in order to reuse if it is still valid
        if (requires) {
          _cookies = cookies;
          cookie = "${cookies.policy.key}=${cookies.policy.value};${cookies.signature.key}=${cookies.signature.value};${cookies.keyPairId.key}=${cookies.keyPairId.value}";
        }

        final Map<String, dynamic> withPlayerId = Map.of(arguments)
          ..['playerId'] = playerId
          ..['cookie'] = cookie;

        return _channel
            .invokeMethod(method, withPlayerId)
            .then((result) => (result as int));
      });
    });
  }

  int enqueue(
    Media media, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) {
    _queue.add(media);
    return Ok;
  }

  int enqueueAll(
    List<Media> items, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) {
    _queue.addAll(items);
    return Ok;
  }

  int remove(Media media) {
    _queue.remove(media);
    return Ok;
  }

  int removeAll() {
    _queue.removeAll();
    return Ok;
  }

  int clear() => removeAll();

  Media get current => _queue.current;

  List<Media> get items => _queue.items;

  int get size => _queue.size;

  Media get top => _queue.top;

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
  }) async {
    final media = _queue.move(pos);
    _queue.play(media);
    _notifyPlayerStatusChangeEvent(EventType.PLAY_REQUESTED);
    return _doPlay(_queue.current);
  }

  Future<int> _doPlay(
    Media media, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) async {
    volume ??= 1.0;
    respectSilence ??= false;
    stayAwake ??= false;

    if (autoPlay) {
      _notifyBeforePlayEvent((loadOnly) => {});

      return invokePlay(media, {
        'url': media.url,
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
          'url': media.url,
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
    final int result = await _invokeMethod('play', args);
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
    return seek(Duration(seconds: 0));
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
    final current = _queue.current;
    var previous = _queue.previous();
    if (previous == null) {
      return NotOk;
    }

    if (previous == current) {
      return _rewind(current);
    } else {
      _notifyChangeToPrevious(previous);
      return _doPlay(previous);
    }
  }

  Future<int> next() async {
    return _doNext(true);
  }

  Future<int> _doNext(bool shallNotify) async {
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
      return _doPlay(next);
    }

    if (repeatMode == RepeatMode.TRACK) {
      return rewind();
    } else {
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
            return NotOk;
          } else if (repeatMode == RepeatMode.QUEUE) {
            next = _queue.restart();
          } else {
            // this should not happen!
            return NotOk;
          }
        }
      }

      if (shallNotify) {
        _notifyChangeToNext(next);
      }
      return _doPlay(next);
    }
  }

  Future<int> pause() async {
    _notifyPlayerStatusChangeEvent(EventType.PAUSE_REQUEST);
    final int result = await _invokeMethod('pause');
    return result;
  }

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

  void shuffle() {
    _queue.shuffle();
  }

  void unshuffle() {
    _queue.unshuffle();
  }

  Future<int> seek(Duration position) {
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
    _notifyPlayerStateChangeEvent(player, EventType.FINISHED_PLAYING);
    switch (player.repeatMode) {
      case RepeatMode.NONE:
      case RepeatMode.QUEUE:
        player._doNext(false);
        break;

      case RepeatMode.TRACK:
        player.rewind();
        break;
    }
  }

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    final Map<dynamic, dynamic> callArgs = call.arguments as Map;
    _log('_platformCallHandler call ${call.method} $callArgs');

    final playerId = callArgs['playerId'] as String;
    final Player player = players[playerId];

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
        player.state = PlayerState.STOPPED;
        _notifyPlayerErrorEvent(player, 'error');
        break;
      case 'state.change':
        final state = callArgs['state'];
        player.state = PlayerState.values[state];

        switch (player.state) {
          case PlayerState.IDLE:
            break;

          case PlayerState.BUFFERING:
            _notifyPlayerStateChangeEvent(player, EventType.BUFFERING);
            break;

          case PlayerState.PLAYING:
            _notifyPlayerStateChangeEvent(player, EventType.PLAYING);
            break;

          case PlayerState.PAUSED:
            _notifyPlayerStateChangeEvent(player, EventType.PAUSED);
            break;

          case PlayerState.STOPPED:
            _notifyPlayerStateChangeEvent(player, EventType.STOP_REQUESTED);
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
      default:
        _log('Unknown method ${call.method} ');
    }
  }

  _notifyChangeToNext(Media media) {
    _eventStreamController.add(Event(type: EventType.NEXT, media: media));
  }

  _notifyChangeToPrevious(Media media) {
    _eventStreamController.add(Event(type: EventType.PREVIOUS, media: media));
  }

  _notifyRewind(Media media) async {
    final positionInMilli = await getCurrentPosition();
    final durationInMilli = await getDuration();

    _eventStreamController.add(Event(
      type: EventType.REWIND,
      media: media,
      position: Duration(milliseconds: positionInMilli),
      duration: Duration(milliseconds: durationInMilli),
    ));
  }

  _notifyForward(Media media) async {
    final positionInMilli = await getCurrentPosition();
    final durationInMilli = await getDuration();

    _eventStreamController.add(Event(
      type: EventType.FORWARD,
      media: media,
      position: Duration(milliseconds: positionInMilli),
      duration: Duration(milliseconds: durationInMilli),
    ));
  }

  _notifyPlayerStatusChangeEvent(EventType type) {
    _eventStreamController.add(Event(type: type, media: _queue.current));
  }

  _notifyBeforePlayEvent(Function(bool) operation) {
    _eventStreamController
        .add(BeforePlayEvent(media: _queue.current, operation: operation));
  }

  static _notifyDurationChangeEvent(Player player, Duration newDuration) {
    player._eventStreamController.add(DurationChangeEvent(
        media: player._queue.current, duration: newDuration));
  }

  static _notifyPlayerStateChangeEvent(Player player, EventType eventType) {
    player._eventStreamController
        .add(Event(type: eventType, media: player._queue.current));
  }

  static _notifyPlayerErrorEvent(Player player, String error) {
    player._eventStreamController.add(Event(
        type: EventType.ERROR_OCCURED,
        media: player._queue.current,
        error: error));
  }

  static _notifyPositionChangeEvent(
      Player player, Duration newPosition, Duration newDuration) {
    player._eventStreamController.add(PositionChangeEvent(
        media: player._queue.current,
        position: newPosition,
        duration: newDuration));
  }

  static void _log(String param) {
    if (logEnabled) {
      print(param);
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
