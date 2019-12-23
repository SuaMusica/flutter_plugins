import 'dart:async';

import 'package:flutter/services.dart';
import 'package:smads/adevent.dart';

class SMAds {
  static const Ok = 1;
  static const NotOk = -1;
  static final MethodChannel _channel = const MethodChannel('smads')
    ..setMethodCallHandler(platformCallHandler);
  
  static SMAds lastAd;

  final StreamController<AdEvent> _eventStreamController =
      StreamController<AdEvent>();

  Stream<AdEvent> _stream;

  Stream<AdEvent> get onEvent {
    if (_stream == null) {
      _stream = _eventStreamController.stream.asBroadcastStream();
    }
    return _stream;
  }

  Future<int> load(Map<String, dynamic> args) async {
    SMAds.lastAd = this;
    final int result = await _channel.invokeMethod('load', args);
    return result;
  }

  Future<int> play() async {
    final int result = await _channel.invokeMethod('play');
    return result;
  }

  static void _log(String param) {
    print(param);
  }

  static Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      _log('Unexpected error: $ex');
    }
  }

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    final Map<dynamic, dynamic> callArgs = call.arguments as Map<dynamic, dynamic>;
    _log('_platformCallHandler call ${call.method} $callArgs');

    switch (call.method) {
      case 'onAdEvent':
        if (lastAd != null && lastAd._eventStreamController != null &&
            !lastAd._eventStreamController.isClosed) {
          lastAd._eventStreamController.add(AdEvent.fromMap(callArgs));
        }

        break;

      default:
        _log('Unknown method ${call.method} ');
    }
  }
}
