import 'package:flutter/services.dart';
import 'package:smads/pre_roll_event_handler.dart';
import 'package:smads/pre_roll_events.dart';

class PreRollController extends PreRollEventHandler {
  final MethodChannel _channel;

  PreRollController(Function(PreRollEvent, Map<String, dynamic>) listener)
      : _channel = MethodChannel('suamusica/pre_roll'),
        super(listener) {
    _channel.setMethodCallHandler(handleEvent);
  }

  Future<int> get screenStatus async =>
      await _channel.invokeMethod('screen_status');

  void pause() {
    _channel.invokeMethod("pause");
  }

  void play() {
    _channel.invokeMethod("play");
  }

  void skip() {
    _channel.invokeMethod("skip");
  }

  void load(Map<String, dynamic>? args) {
    _channel.invokeMethod("load", args ?? {});
  }

  void dispose() {
    _channel.invokeMethod('dispose');
  }
}
