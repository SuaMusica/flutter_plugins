import 'dart:async';

import 'package:flutter/services.dart';

class SMAds {
  static const Ok = 1;
  static const NotOk = -1;
  static const MethodChannel _channel =
      const MethodChannel('smads');

  Future<int> load(Map<String, dynamic> args) async {
    final int result = await _channel.invokeMethod('load', args);
    return result;
  }

  Future<int> play() async {
    final int result = await _channel.invokeMethod('play');
    return result;
  }
}
