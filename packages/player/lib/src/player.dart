import 'dart:async';

import 'package:aws/src/cloud_front/cookies_for_custom_policy.dart';
import 'package:flutter/services.dart';
import 'package:suamusica_player/src/media.dart';
import 'package:uuid/uuid.dart';

import 'player_state.dart';

class Player {
  static const MethodChannel _channel = const MethodChannel('suamusica_player');

  static final _uuid = Uuid();

  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();

  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  final StreamController<void> _completionController =
      StreamController<void>.broadcast();

  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  static final players = Map<String, Player>();

  static bool logEnabled = false;

  PlayerState _playerState;

  final Future<String> Function() cookieSigner;

  PlayerState get state => _playerState;

  set state(PlayerState state) {
    _playerStateController.add(state);
    _playerState = state;
  }

  Stream<PlayerState> get onPlayerStateChanged => _playerStateController.stream;

  Stream<Duration> get onAudioPositionChanged => _positionController.stream;

  Stream<Duration> get onDurationChanged => _durationController.stream;

  Stream<void> get onPlayerCompletion => _completionController.stream;

  Stream<String> get onPlayerError => _errorController.stream;

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

    final cookie = (() async => await cookieSigner())();

    return cookie.then((cookie) {
      final Map<String, dynamic> withPlayerId = Map.of(arguments)
        ..['playerId'] = playerId
        ..['cookie'] = cookie;

      return _channel
          .invokeMethod(method, withPlayerId)
          .then((result) => (result as int));
    });
  }

  Future<int> play(
    Media media, {
    double volume = 1.0,
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) async {
    volume ??= 1.0;
    respectSilence ??= false;
    stayAwake ??= false;

    final int result = await _invokeMethod('play', {
      'url': media.url,
      'is_local': media.isLocal,
      'volume': volume,
      'position': position?.inMilliseconds,
      'respectSilence': respectSilence,
      'stayAwake': stayAwake,
    });

    if (result == 1) {
      state = PlayerState.PLAYING;
    }

    return result;
  }

  Future<int> pause() async {
    final int result = await _invokeMethod('pause');

    if (result == 1) {
      state = PlayerState.PAUSED;
    }

    return result;
  }

  Future<int> stop() async {
    final int result = await _invokeMethod('stop');

    if (result == 1) {
      state = PlayerState.STOPPED;
    }

    return result;
  }

  Future<int> resume() async {
    final int result = await _invokeMethod('resume');

    if (result == 1) {
      state = PlayerState.PLAYING;
    }

    return result;
  }

  Future<int> release() async {
    final int result = await _invokeMethod('release');

    if (result == 1) {
      state = PlayerState.STOPPED;
    }

    return result;
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
    final value = callArgs['value'];

    switch (call.method) {
      case 'audio.onDuration':
        Duration newDuration = Duration(milliseconds: value);
        player._durationController.add(newDuration);
        break;
      case 'audio.onCurrentPosition':
        Duration newDuration = Duration(milliseconds: value);
        player._positionController.add(newDuration);
        break;
      case 'audio.onComplete':
        player.state = PlayerState.COMPLETED;
        player._completionController.add(null);
        break;
      case 'audio.onError':
        player.state = PlayerState.STOPPED;
        player._errorController.add(value);
        break;
      default:
        _log('Unknown method ${call.method} ');
    }
  }

  static void _log(String param) {
    if (logEnabled) {
      print(param);
    }
  }

  Future<void> dispose() async {
    List<Future> futures = [];

    if (!_playerStateController.isClosed)
      futures.add(_playerStateController.close());
    if (!_positionController.isClosed) futures.add(_positionController.close());
    if (!_durationController.isClosed) futures.add(_durationController.close());
    if (!_completionController.isClosed)
      futures.add(_completionController.close());
    if (!_errorController.isClosed) futures.add(_errorController.close());

    await Future.wait(futures);
  }
}
