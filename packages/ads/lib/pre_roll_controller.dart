import 'package:flutter/services.dart';
import 'package:smads/pre_roll_event_handler.dart';
import 'package:smads/pre_roll_events.dart';

class PreRollController extends PreRollEventHandler {
  final MethodChannel _channel;

  PreRollController(Function(PreRollEvent, Map<String, dynamic>) listener,
      Future<bool> Function() canIPlay)
      : _channel = MethodChannel('suamusica/pre_roll'),
        _canIPlay = canIPlay ?? _iCanPlay(),
        super(listener) {
    if (listener != null) {
      _channel.setMethodCallHandler(handleEvent);
    }
  }

  final Future<bool> Function() _canIPlay;

  Future<int> get screenStatus async =>
      await _channel.invokeMethod('screen_status');

  static Future<bool> _iCanPlay() => Future.value(true);

  void pause() {
    _channel.invokeMethod("pause");
  }

  void play() {
    _canIPlay.call().then((value) => {
      if (value) {
        _channel.invokeMethod("play")
      }
    });
  }

  void load(Map<String, dynamic> args) {
    _channel.invokeMethod("load", args ?? {});
  }

  void dispose() {
    _channel.invokeMethod('dispose');
  }
}