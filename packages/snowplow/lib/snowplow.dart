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
      return await _channel.invokeMethod<bool?>('setUserId', args) ?? false;
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

      return await _channel.invokeMethod('trackPageview', args) ?? false;
    } on PlatformException catch (e) {
      print("Failed ${e.message}");
      return Future.value(false);
    }
  }

  Future<bool> trackCustomEvent({
    required String customScheme,
    required Map<String, Object> eventMap,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{
        'customScheme': customScheme,
        'eventMap': eventMap,
      };
      return await _channel.invokeMethod('trackCustomEvent', args) ?? false;
    } on PlatformException catch (e) {
      print("Failed ${e.message}");
      return Future.value(false);
    }
  }

  Future<bool> trackEvent({
    String? category,
    String? action,
    String? label,
    String? property,
    int? value,
    String? pageName,
  }) async {
    try {
      Map<String, dynamic> args = <String, dynamic>{
        'category': category ?? "",
        'action': action ?? "",
        'label': label ?? "",
        'property': property ?? "",
        'value': value ?? 0,
        'pageName': pageName ?? "",
      };
      return await _channel.invokeMethod('trackEvent', args) ?? false;
    } catch (e) {
      print("Failed $e");
      return Future.value(false);
    }
  }
}
