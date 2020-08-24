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

  Future<bool> trackCustomEvent(
      {String customScheme, Map<String, Object> eventMap}) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{
        'customScheme': customScheme,
        'eventMap': eventMap,
      };
      return _channel.invokeMethod('trackCustomEvent', args);
    } on PlatformException catch (e) {
      print("Failed ${e.message}");
      return Future.value(false);
    }
  }

  Future<bool> trackEvent({
    String category,
    String action,
    String label,
    String property,
    int value,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{
        'category': category,
        'action': action,
        'label': label,
        'property': property,
        'value': value
      };
      return _channel.invokeMethod('trackEvent', args);
    } catch (e) {
      print("Failed ${e.message}");
      return Future.value(false);
    }
  }
}
