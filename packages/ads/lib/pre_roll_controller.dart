import 'package:flutter/services.dart';
import 'package:smads/pre_roll_event_handler.dart';

class PreRollController extends PreRollEventHandler {
  final MethodChannel _channel;

  PreRollController(int id, Function(String, Map<String, dynamic>) listener)
      : _channel = MethodChannel('suamusica/pre_roll_$id'),
        super(listener) {
    if (listener != null) {
      _channel.setMethodCallHandler(handleEvent);
      _channel.invokeMethod('setListener');
    }
  }
  void pause() {
    _channel.invokeMethod("pause");
  }

  void play() {
    _channel.invokeMethod("play");
  }

  void dispose() {
    _channel.invokeMethod('dispose');
  }
}
