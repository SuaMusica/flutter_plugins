import 'dart:async';

import 'package:aws/aws.dart';
import 'package:flutter/services.dart';
import 'package:suamusica_player/src/event.dart';
import 'package:suamusica_player/src/event_type.dart';
import 'package:suamusica_player/src/media.dart';
import 'package:suamusica_player/src/new_duration_event.dart';
import 'package:suamusica_player/src/new_position_event.dart';
import 'package:suamusica_player/src/queue.dart';
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
  PlayerState _playerState = PlayerState.IDLE;
  Queue _queue = Queue();

  final StreamController<Event> _eventStreamController =
      StreamController<Event>.broadcast();

  final Future<CookiesForCustomPolicy> Function() cookieSigner;

  PlayerState get state => _playerState;

  set state(PlayerState state) {
    _playerState = state;
  }

  Stream<Event> get onEvent => _eventStreamController.stream;

  String playerId;

  Player(this.cookieSigner) {
    playerId = _uuid.v4();
    players[playerId] = this;
  }

  Future<int> _invokeMethod(
    String method, [
    Map<String, dynamic> arguments,
  ]) async {
    arguments ??= const {};

    Future<CookiesForCustomPolicy> cookies = Future.value(_cookies);
    if (_cookies == null || !_cookies.isValid()) {
      cookies = (() async => await cookieSigner())();
    }

    return cookies.then((cookies) {
      // we need to save it in order to reuse if it is still valid
      _cookies = cookies;
      final cookie =
          "${cookies.policy.key}=${cookies.policy.value};${cookies.signature.key}=${cookies.signature.value};${cookies.keyPairId.key}=${cookies.keyPairId.value}";

      final Map<String, dynamic> withPlayerId = Map.of(arguments)
        ..['playerId'] = playerId
        ..['cookie'] = cookie;

      return _channel
          .invokeMethod(method, withPlayerId)
          .then((result) => (result as int));
    });
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

  Future<int> play(
    Media media, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) async {
    _queue.addOnTop(media);
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

    _notifyPlayerStatusChangeEvent(EventType.BEFORE_PLAY);

    final int result = await _invokeMethod('play', {
      'url': media.url,
      'is_local': media.isLocal,
      'volume': volume,
      'position': position?.inMilliseconds,
      'respectSilence': respectSilence,
      'stayAwake': stayAwake,
    });

    if (result == Ok) {
      _notifyPlayerStatusChangeEvent(EventType.PLAYING);
      state = PlayerState.PLAYING;
    }

    return result;
  }

  Future<int> next() async {
    var media = _queue.next();
    if (media == null) {
      return NotOk;
    }
    _notifyChangeToNext(media);
    return _doPlay(media);
  }

  Future<int> previous() async {
    var media = _queue.previous();
    if (media == null) {
      return NotOk;
    }
    _notifyChangeToPrevious(media);
    return _doPlay(media);
  } 

  Future<int> pause() async {
    _notifyPlayerStatusChangeEvent(EventType.PAUSED_REQUEST);
    final int result = await _invokeMethod('pause');

    if (result == Ok) {
      state = PlayerState.PAUSED;
      _notifyPlayerStatusChangeEvent(EventType.PAUSED);
    }

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
      state = PlayerState.PLAYING;
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

  List<Media> items() => _queue.items();

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

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    final Map<dynamic, dynamic> callArgs = call.arguments as Map;
    _log('_platformCallHandler call ${call.method} $callArgs');

    final playerId = callArgs['playerId'] as String;
    final Player player = players[playerId];

    switch (call.method) {
      case 'audio.onDuration':
        final duration = callArgs['duration'];
        Duration newDuration = Duration(milliseconds: duration);
        _notifyDurationChangeEvent(player, newDuration);
        break;
      case 'audio.onCurrentPosition':
        final position = callArgs['position'];
        Duration newPosition = Duration(milliseconds: position);
        final duration = callArgs['duration'];
        Duration newDuration = Duration(milliseconds: duration);
        _notifyPositionChangeEvent(player, newPosition, newDuration);
        break;
      case 'audio.onComplete':
        player.state = PlayerState.COMPLETED;
        // player._completionController.add(null);
        break;
      case 'audio.onError':
        player.state = PlayerState.STOPPED;
        // player._errorController.add(value);
        break;
      case 'state.change':
        final state = callArgs['state'];
        player.state = PlayerState.values[state];
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

  _notifyPlayerStatusChangeEvent(EventType type) {
    _eventStreamController.add(Event(type: type, media: _queue.current));
  }

  static _notifyDurationChangeEvent(Player player, Duration newDuration) {
    player._eventStreamController.add(NewDurationEvent(
        type: EventType.NEW_DURATION,
        media: player._queue.current,
        duration: newDuration));
  }

  static _notifyPositionChangeEvent(
      Player player, Duration newPosition, Duration newDuration) {
    player._eventStreamController.add(NewPositionEvent(
        type: EventType.NEW_POSITION,
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
