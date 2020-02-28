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

  final StreamController<List<DownloadedContent>> _downloadedStreamController =
      StreamController<List<DownloadedContent>>.broadcast();

  void dipose() {
    _downloadedStreamController.close();
  }

  Stream<List<DownloadedContent>> get downloadedContent =>
      _downloadedStreamController.stream;

  Future<int> getLegacyDownloadContent() async {
    final int result = await _channel.invokeMethod('requestDownloadedContent');

    return result;
  }

  Future<int> deleteOldDatabase() async {
    final int result = await _channel.invokeMethod('deleteOldContent');

    return result;
  }

  Future<Map<dynamic, dynamic>> requestLoggedUser() async {
    final result = await _channel.invokeMethod('requestLoggedUser');

    if (result != null && result is Map<dynamic, dynamic>) {
      return result;
    }

    return null;
  }

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'downloadedContent':
        if (instance != null &&
            instance._downloadedStreamController != null &&
            !instance._downloadedStreamController.isClosed) {
          final content = (call.arguments as List<dynamic>)
              .where((item) => item is Map<dynamic, dynamic>)
              .map(
                (item) =>
                    DownloadedContent.fromJson(item as Map<dynamic, dynamic>),
              )
              .toList();

          instance._downloadedStreamController.add(content);
        }

        break;

      default:
        _log('Unknown method ${call.method} ');
    }
  }
}
