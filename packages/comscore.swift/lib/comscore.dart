import 'dart:async';

import 'package:flutter/services.dart';

class Comscore {
  static const MethodChannel _channel = const MethodChannel('comscore');

  static Future<bool> initialize({
    required String publisherId,
    bool secureTransmissionEnabled = false,
  }) async {
    Map<String, dynamic> arguments = const {};
    final Map<String, dynamic> args = Map.of(arguments)
      ..['publisherId'] = publisherId
      ..['secureTransmissionEnabled'] = secureTransmissionEnabled;
    return await _channel
        .invokeMethod('initialize', args)
        .then((result) => (result as bool));
  }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
