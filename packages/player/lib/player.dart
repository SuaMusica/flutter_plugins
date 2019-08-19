import 'dart:async';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'player_state.dart';

class Player {
  static const MethodChannel _channel =
      const MethodChannel('suamusica_player');

  static final _uuid = Uuid();

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

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

  /// Reference [Map] with all the players created by the application.
  ///
  /// This is used to exchange messages with the [MethodChannel]
  /// (there is only one).
  static final players = Map<String, Player>();

  /// Enables more verbose logging.
  static bool logEnabled = false;

  PlayerState _PlayerState;

  PlayerState get state => _PlayerState;

  set state(PlayerState state) {
    _playerStateController.add(state);
    _PlayerState = state;
  }

  /// Stream of changes on player state.
  Stream<PlayerState> get onPlayerStateChanged =>
      _playerStateController.stream;

  /// Stream of changes on audio position.
  ///
  /// Roughly fires every 200 milliseconds. Will continuously update the
  /// position of the playback if the status is [PlayerState.PLAYING].
  ///
  /// You can use it on a progress bar, for instance.
  Stream<Duration> get onAudioPositionChanged => _positionController.stream;

  /// Stream of changes on audio duration.
  ///
  /// An event is going to be sent as soon as the audio duration is available
  /// (it might take a while to download or buffer it).
  Stream<Duration> get onDurationChanged => _durationController.stream;

  /// Stream of player completions.
  ///
  /// Events are sent every time an audio is finished, therefore no event is
  /// sent when an audio is paused or stopped.
  ///
  /// [ReleaseMode.LOOP] also sends events to this stream.
  Stream<void> get onPlayerCompletion => _completionController.stream;

  /// Stream of player errors.
  ///
  /// Events are sent when an unexpected error is thrown in the native code.
  Stream<String> get onPlayerError => _errorController.stream;

  /// An unique ID generated for this instance of [Player].
  ///
  /// This is used to properly exchange messages with the [MethodChannel].
  String playerId;

  /// Creates a new instance and assigns an unique id to it.
  Player() {
    playerId = _uuid.v4();
    players[playerId] = this;
  }

  Future<int> _invokeMethod(
    String method, [
    Map<String, dynamic> arguments,
  ]) {
    arguments ??= const {};

    final Map<String, dynamic> withPlayerId = Map.of(arguments)
      ..['playerId'] = playerId;

    return _channel
        .invokeMethod(method, withPlayerId)
        .then((result) => (result as int));
  }

  /// Plays an audio.
  ///
  /// If [isLocal] is true, [url] must be a local file system path.
  /// If [isLocal] is false, [url] must be a remote URL.
  Future<int> play(
    String url, {
    bool isLocal = false,
    double volume = 1.0,
    // position must be null by default to be compatible with radio streams
    Duration position,
    bool respectSilence = false,
    bool stayAwake = false,
  }) async {
    isLocal ??= false;
    volume ??= 1.0;
    respectSilence ??= false;
    stayAwake ??= false;

    final int result = await _invokeMethod('play', {
      'url': url,
      'isLocal': isLocal,
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

  /// Pauses the audio that is currently playing.
  ///
  /// If you call [resume] later, the audio will resume from the point that it
  /// has been paused.
  Future<int> pause() async {
    final int result = await _invokeMethod('pause');

    if (result == 1) {
      state = PlayerState.PAUSED;
    }

    return result;
  }

  /// Stops the audio that is currently playing.
  ///
  /// The position is going to be reset and you will no longer be able to resume
  /// from the last point.
  Future<int> stop() async {
    final int result = await _invokeMethod('stop');

    if (result == 1) {
      state = PlayerState.STOPPED;
    }

    return result;
  }

  /// Resumes the audio that has been paused or stopped, just like calling
  /// [play], but without changing the parameters.
  Future<int> resume() async {
    final int result = await _invokeMethod('resume');

    if (result == 1) {
      state = PlayerState.PLAYING;
    }

    return result;
  }

  /// Releases the resources associated with this media player.
  ///
  /// The resources are going to be fetched or buffered again as soon as you
  /// call [play] or [setUrl].
  Future<int> release() async {
    final int result = await _invokeMethod('release');

    if (result == 1) {
      state = PlayerState.STOPPED;
    }

    return result;
  }

  /// Moves the cursor to the desired position.
  Future<int> seek(Duration position) {
    return _invokeMethod('seek', {'position': position.inMilliseconds});
  }

  /// Sets the volume (amplitude).
  ///
  /// 0 is mute and 1 is the max volume. The values between 0 and 1 are linearly
  /// interpolated.
  Future<int> setVolume(double volume) {
    return _invokeMethod('setVolume', {'volume': volume});
  }

  /// Sets the URL.
  ///
  /// Unlike [play], the playback will not resume.
  ///
  /// The resources will start being fetched or buffered as soon as you call
  /// this method.
  Future<int> setUrl(String url, {bool isLocal: false}) {
    return _invokeMethod('setUrl', {'url': url, 'isLocal': isLocal});
  }

  /// Get audio duration after setting url.
  /// Use it in conjunction with setUrl.
  ///
  /// It will be available as soon as the audio duration is available
  /// (it might take a while to download or buffer it if file is not local).
  Future<int> getDuration() {
    return _invokeMethod('getDuration');
  }

  // Gets audio current playing position
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

  /// Closes all [StreamController]s.
  ///
  /// You must call this method when your [Player] instance is not going to
  /// be used anymore.
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
