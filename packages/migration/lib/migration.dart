import 'dart:async';

import 'package:flutter/services.dart';
import 'package:migration/downloaded_content.dart';

class Migration {
  Migration._();

  static Migration _instance;

  static Migration get instance {
    if (_instance == null) {
      _instance = Migration._();
    }
    return _instance;
  }

  static final MethodChannel _channel = const MethodChannel('migration')
    ..setMethodCallHandler(platformCallHandler);

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

  final StreamController<List<DownloadedContent>> _streamController =
      StreamController<List<DownloadedContent>>.broadcast();

  void dipose() {
    _streamController.close();
  }

  Stream<List<DownloadedContent>> get downloadedContent =>
      _streamController.stream;

  Future<int> getLegacyDownloadContent() async {
    final int result = await _channel.invokeMethod('requestDownloadedContent');

    return result;
  }

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'downloadedContent':
        if (instance != null &&
            instance._streamController != null &&
            !instance._streamController.isClosed) {
          final content = (call.arguments as List<dynamic>)
              .where((item) => item is Map<dynamic, dynamic>)
              .map(
                (item) =>
                    DownloadedContent.fromJson(item as Map<dynamic, dynamic>),
              )
              .toList();

          instance._streamController.add(content);
        }

        break;

      default:
        _log('Unknown method ${call.method} ');
    }
  }
}
