import 'dart:async';

import 'package:flutter/services.dart';
import 'package:smads/adevent.dart';

class SMAds {
  SMAds({
    this.adUrl,
    this.contentUrl,
  });

  final adUrl;
  final contentUrl;
  static const Ok = 1;
  static const NoConnectivity = -1;
  static const ScreenIsLocked = -2;
  static const UnlockedScreen = 1;
  static const LockedScreen = 0;

  static final MethodChannel _channel = MethodChannel('smads')
    ..setMethodCallHandler(platformCallHandler);

  static SMAds? lastAd;
  Function? onComplete;
  Function(int?)? onError;

  final StreamController<AdEvent> _eventStreamController =
      StreamController<AdEvent>();

  late Stream<AdEvent> _stream;

  Stream<AdEvent> get onEvent {
    _stream = _eventStreamController.stream.asBroadcastStream();

    return _stream;
  }

  Future<int?> load(
    Map<String, dynamic> args, {
    Function? onComplete,
    Function(int?)? onError,
  }) async {
    this.onComplete = onComplete;
    this.onError = onError;
    SMAds.lastAd = this;
    args["__URL__"] = adUrl;
    args["__CONTENT__"] = contentUrl;
    final int result = await _channel.invokeMethod('load', args) ?? 0;
    return result;
  }

  Future<int?> get screenStatus async =>
      await _channel.invokeMethod('screen_status');

  static void _log(String param) {
    print(param);
  }

  void dispose() {
    _eventStreamController.close();
  }

  static Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      _log('Unexpected error: $ex');
    }
  }

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    final Map<dynamic, dynamic> callArgs = call.arguments;
    _log('_platformCallHandler call ${call.method} $callArgs');

    switch (call.method) {
      case 'onAdEvent':
        lastAd?._eventStreamController.add(AdEvent.fromMap(callArgs));

        break;

      case 'onComplete':
        lastAd?.onComplete?.call();

        break;

      case 'onError':
        final error = callArgs["error"];
        lastAd?.onError?.call(error);

        break;

      default:
        _log('Unknown method ${call.method} ');
    }
  }
}
