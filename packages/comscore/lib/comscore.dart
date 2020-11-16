
import 'dart:async';

import 'package:flutter/services.dart';

class Comscore {
  static const MethodChannel _channel =
      const MethodChannel('comscore');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
