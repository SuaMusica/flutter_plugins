import 'dart:async';

import 'package:flutter/services.dart';

class Migration {
  static const MethodChannel _channel = const MethodChannel('migration');

  static void _log(String param) {
    print(param);
  }

  Future<int> getLegacyDownloadContent(Map<String, dynamic> args) async {
    final int result =
        await _channel.invokeMethod('getLegacyDownloadedContent', args);

    return result;
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
      case 'getLegacyDownloadedContent':
        break;

      default:
        _log('Unknown method ${call.method} ');
    }
  }
}
