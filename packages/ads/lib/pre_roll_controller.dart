import 'package:flutter/services.dart';
import 'package:smads/pre_roll_event_handler.dart';
import 'package:smads/pre_roll_events.dart';

class PreRollController extends PreRollEventHandler {
  final MethodChannel _channel;

  PreRollController(
      int id, Function(PreRollEvent, Map<String, dynamic>) listener)
      : _channel = MethodChannel('suamusica/pre_roll_$id'),
        super(listener) {
    if (listener != null) {
      _channel.setMethodCallHandler(handleEvent);
      // _channel.invokeMethod('setListener');
    }
  }
  void pause() {
    _channel.invokeMethod("pause");
  }

  void play() {
    _channel.invokeMethod("play");
  }

  void load(Map<String, dynamic> args) {
    _channel.invokeMethod("load", args ?? {});
  }

  void dispose() {
    _channel.invokeMethod('dispose');
  }
}