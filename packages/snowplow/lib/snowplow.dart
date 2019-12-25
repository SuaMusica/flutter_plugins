import 'dart:async';

import 'package:flutter/services.dart';

class Snowplow {
  static const MethodChannel _channel =
      const MethodChannel('com.suamusica.br/snowplow');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<bool> logPageView(String name) async {
    try {
      return _channel.invokeMethod('logPageView');
    } on PlatformException catch (e) {
      print("Failed ${e.message}");
      return Future.value(false);
    }
  }
}
