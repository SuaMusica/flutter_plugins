import 'dart:async';

import 'package:flutter/services.dart';

class Snowplow {
  static const MethodChannel _channel =
      const MethodChannel('com.suamusica.br/snowplow');

  Future<bool> setUserId(String userId) async {
    try {
      Map<String, String> args = <String, String>{
        'userId': userId,
      };
      return _channel.invokeMethod('setUserId', args);
    } on PlatformException catch (e) {
      print("Failed ${e.message}");
      return Future.value(false);
    }
  }

  Future<bool> logPageView(String name) async {
    try {
      Map<String, String> args = <String, String>{
        'screenName': name,
      };
      return _channel.invokeMethod('trackPageview', args);
    } on PlatformException catch (e) {
      print("Failed ${e.message}");
      return Future.value(false);
    }
  }
}
