import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:smads/adevent.dart';

class SMAds {
  SMAds({
    @required this.adUrl,
    @required this.contentUrl,
  });

  final adUrl;
  final contentUrl;
  static const Ok = 1;
  static const NotOk = -1;
  static final MethodChannel _channel = const MethodChannel('smads')
    ..setMethodCallHandler(platformCallHandler);

  static SMAds lastAd;
  Function onComplete;

  final StreamController<AdEvent> _eventStreamController =
      StreamController<AdEvent>();

  Stream<AdEvent> _stream;

  Stream<AdEvent> get onEvent {
    if (_stream == null) {
      _stream = _eventStreamController.stream.asBroadcastStream();
    }
    return _stream;
  }

  Future<int> load(Map<String, dynamic> args, Function onComplete) async {
    this.onComplete = onComplete;
    SMAds.lastAd = this;
    args["__URL__"] = adUrl;
    args["__CONTENT__"] = contentUrl;
    final int result = await _channel.invokeMethod('load', args);
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
    final Map<dynamic, dynamic> callArgs =
        call.arguments as Map<dynamic, dynamic>;
    _log('_platformCallHandler call ${call.method} $callArgs');

    switch (call.method) {
      case 'onAdEvent':
        if (lastAd != null &&
            lastAd._eventStreamController != null &&
            !lastAd._eventStreamController.isClosed) {
          lastAd._eventStreamController.add(AdEvent.fromMap(callArgs));
        }

        break;

      case 'onComplete':
        if (lastAd != null && lastAd.onComplete != null) {
          lastAd.onComplete();
        }

        break;

      default:
        _log('Unknown method ${call.method} ');
    }
  }
}
