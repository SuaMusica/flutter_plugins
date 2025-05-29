import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:smplayer/src/models/event.dart';
import 'package:smplayer/src/enums/event_type.dart';
import 'package:smplayer/src/core/player.dart';
import 'package:smplayer/src/enums/player_state.dart';
import 'package:smplayer/src/enums/repeat_mode.dart';
import 'package:smplayer/src/events/duration_change_event.dart';
import 'package:smplayer/src/events/position_change_event.dart';
import 'package:smplayer/src/services/isar_service.dart';
import 'package:smplayer/src/models/previous_playlist_model.dart';
import 'dart:async';

class PlayerChannel {
  static const String CHANNEL = 'suamusica.com.br/player';
  static const int ok = 1;
  static const int notOk = -1;

  final Player _player;
  final MethodChannel _channel;

  PlayerChannel(this._player) : _channel = const MethodChannel(CHANNEL) {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  Future<int> invokeMethod(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    arguments ??= const {};
    return _channel
        .invokeMethod(method, arguments)
        .then((result) => result ?? Future.value(ok));
  }

  Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      _log('Unexpected error: $ex');
    }
  }

  Future<void> _handleOnComplete() async {
    _player.state = PlayerState.COMPLETED;
    _notifyPlayerStateChangeEvent(EventType.FINISHED_PLAYING, "");
  }

  Future<void> _doHandlePlatformCall(MethodCall call) async {
    final currentMedia = _player.currentMedia;
    final currentIndex = _player.currentIndex;
    final Map<dynamic, dynamic> callArgs = call.arguments as Map;
    if (call.method != 'audio.onCurrentPosition') {
      _log('_platformCallHandler call ${call.method} $callArgs');
    }
    switch (call.method) {
      case 'audio.onDuration':
        final duration = callArgs['duration'];
        if (duration > 0) {
          Duration newDuration = Duration(milliseconds: duration);
          _notifyDurationChangeEvent(newDuration);
        }
        break;
      case 'audio.onCurrentPosition':
        final position = callArgs['position'];
        Duration newPosition = Duration(milliseconds: position);
        final duration = callArgs['duration'];
        Duration newDuration = Duration(milliseconds: duration);
        _notifyPositionChangeEvent(newPosition, newDuration);
        break;
      case 'audio.onError':
        _player.state = PlayerState.ERROR;
        final errorType = callArgs['errorType'] ?? 2;

        _notifyPlayerErrorEvent(
          error: 'error',
          errorType: PlayerErrorType.values[errorType],
        );
        break;
      case 'state.change':
        final state = callArgs['state'];
        String error = callArgs['error'] ?? "";
        _log('state.change call ${PlayerState.values[state]}');
        _player.state = PlayerState.values[state];
        switch (_player.state) {
          case PlayerState.STATE_READY:
            _notifyPlayerStateChangeEvent(EventType.STATE_READY, error);
            break;
          case PlayerState.IDLE:
            _notifyPlayerStateChangeEvent(EventType.IDLE, error);
            break;
          case PlayerState.BUFFERING:
            _notifyPlayerStateChangeEvent(EventType.BUFFERING, error);
            break;
          case PlayerState.ITEM_TRANSITION:
            _notifyPlayerStateChangeEvent(EventType.BEFORE_PLAY, error);
            break;
          case PlayerState.PLAYING:
            _notifyPlayerStateChangeEvent(EventType.PLAYING, error);
            break;
          case PlayerState.PAUSED:
            _notifyPlayerStateChangeEvent(EventType.PAUSED, error);
            break;
          case PlayerState.STOPPED:
            _notifyPlayerStateChangeEvent(EventType.STOP_REQUESTED, error);
            break;
          case PlayerState.SEEK_END:
            _notifyPlayerStateChangeEvent(EventType.SEEK_END, error);
            break;
          case PlayerState.BUFFER_EMPTY:
            _notifyPlayerStateChangeEvent(EventType.BUFFER_EMPTY, error);
            break;
          case PlayerState.COMPLETED:
            _handleOnComplete();
            break;
          case PlayerState.STATE_ENDED:
            _notifyPlayerStateChangeEvent(EventType.STATE_ENDED, error);
            break;
          case PlayerState.ERROR:
            final error = callArgs['error'] ?? "Unknown from Source";
            final isPermissionError = (error as String).contains(
              'Permission denied',
            );
            _notifyPlayerErrorEvent(
              error: error,
              errorType: isPermissionError
                  ? PlayerErrorType.PERMISSION_DENIED
                  : null,
            );
            break;
        }
        break;
      case 'commandCenter.onNext':
        _log("Player : Command Center : Got a next request");
        await _player.next();
        if (currentMedia != null) {
          _player.eventController.add(
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
          _player.eventController.add(
            Event(
              type: EventType.PREVIOUS_NOTIFICATION,
              media: currentMedia,
              queuePosition: currentIndex,
            ),
          );
        }
        _player.previous();
        break;
      case 'commandCenter.onPlay':
        if (currentMedia != null) {
          _player.eventController.add(
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
          _player.eventController.add(
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
          _player.eventController.add(
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
        _notifyPlayerStateChangeEvent(EventType.EXTERNAL_RESUME_REQUESTED, "");
        break;
      case 'externalPlayback.pause':
        print("Player: externalPlayback : Pause");
        _notifyPlayerStateChangeEvent(EventType.EXTERNAL_PAUSE_REQUESTED, "");
        break;
      case 'commandCenter.onFavorite':
        final favorite = callArgs['favorite'];
        print("Player: onFavorite : $favorite");
        _notifyPlayerStateChangeEvent(
          favorite ? EventType.FAVORITE_MUSIC : EventType.UNFAVORITE_MUSIC,
          "",
        );
        break;
      case 'cast.mediaFromQueue':
        final index = callArgs['index'];
        _channel.invokeMethod('cast_next_media', _player.items[index].toJson());
        _updateQueueIndexAndNotify(index: index);
        break;
      case 'cast.nextMedia':
      case 'cast.previousMedia':
        final media = call.method == 'cast.nextMedia'
            ? _player.possibleNext(_player.repeatMode)
            : _player.possiblePrevious();
        if (media != null) {
          _channel.invokeMethod('cast_next_media', media.toJson());
          _updateQueueIndexAndNotify(index: _player.items.indexOf(media));
        }
        break;
      case 'SET_CURRENT_MEDIA_INDEX':
        _updateQueueIndexAndNotify(index: callArgs['CURRENT_MEDIA_INDEX']);
        break;
      case 'REPEAT_CHANGED':
        _player.repeatMode = RepeatMode.values[callArgs['REPEAT_MODE']];
        _notifyPlayerStateChangeEvent(EventType.REPEAT_CHANGED, "");
        break;
      case 'SHUFFLE_CHANGED':
        _player.shuffleEnabled = callArgs['SHUFFLE_MODE'];
        _notifyPlayerStateChangeEvent(EventType.SHUFFLE_CHANGED, "");
        break;
      default:
        _log('Unknown method ${call.method} ');
    }
  }

  void _notifyDurationChangeEvent(Duration newDuration) {
    final currentIndex = _player.currentIndex;
    if (_player.currentMedia != null) {
      _player.eventController.add(
        DurationChangeEvent(
          media: _player.currentMedia!,
          queuePosition: currentIndex,
          duration: newDuration,
        ),
      );
    }
  }

  void _notifyPlayerStateChangeEvent(EventType eventType, String error) {
    final currentIndex = _player.currentIndex;
    if (error.isNotEmpty) {
      _notifyPlayerErrorEvent(
        error: error,
        errorType: PlayerErrorType.INFORMATION,
      );
    }
    if (_player.currentMedia != null) {
      _player.eventController.add(
        Event(
          type: eventType,
          media: _player.currentMedia!,
          queuePosition: currentIndex,
        ),
      );
    }
  }

  void _notifyPlayerErrorEvent({
    required String error,
    PlayerErrorType? errorType,
  }) {
    final currentIndex = _player.currentIndex;
    if (_player.currentMedia != null) {
      _player.eventController.add(
        Event(
          type: EventType.ERROR_OCCURED,
          media: _player.currentMedia!,
          queuePosition: currentIndex,
          error: error,
          errorType: errorType ?? PlayerErrorType.UNDEFINED,
        ),
      );
    }
  }

  void _notifyPositionChangeEvent(Duration newPosition, Duration newDuration) {
    final media = _player.currentMedia;
    final currentIndex = _player.currentIndex;
    if (media != null) {
      final position = newPosition.inSeconds;
      _player.eventController.add(
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

  void _log(String param) {
    debugPrint(param);
  }

  void _updateQueueIndexAndNotify({required index}) {
    _player.setIndexAndUpdateIsar(index);
    _notifyPlayerStateChangeEvent(EventType.SET_CURRENT_MEDIA_INDEX, '');
  }
}
