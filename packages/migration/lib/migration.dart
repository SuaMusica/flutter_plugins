import 'dart:async';

import 'package:flutter/services.dart';
import 'package:migration/entities/downloaded_content.dart';
import 'package:migration/entities/android_downloaded_content.dart';

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
    _log('Method Call: ${call.method}');
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      _log('Unexpected error: $ex');
    }
  }

  final StreamController<AndroidDownloadedContent>
      _androidDownloadedStreamController =
      StreamController<AndroidDownloadedContent>.broadcast();

  final StreamController<List<DownloadedContent>> _downloadedStreamController =
      StreamController<List<DownloadedContent>>.broadcast();

  void dipose() {
    _downloadedStreamController.close();
    _androidDownloadedStreamController.close();
  }

  Stream<List<DownloadedContent>> get downloadedContent =>
      _downloadedStreamController.stream;

  Stream<AndroidDownloadedContent> get androidDownloadedContent =>
      _androidDownloadedStreamController.stream;

  Future<int> getLegacyDownloadContent() async {
    final int result = await _channel.invokeMethod('requestDownloadedContent');
    _log("DownloadedContents.getLegacyDownloadContent: $result");
    return result ?? 0;
  }

  Future<List<dynamic>> getId3() async {
    final List<dynamic> result =
        await _channel.invokeMethod('extractId3');
    return result ?? [];
  }

  Future<int> getArtWorks(List<Map<String, String>> items) async {
    final int result =
        await _channel.invokeMethod('extractArt', {"items": items});
    return result ?? 0;
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
          _log("Migration.downloadedContent: ${call.arguments}");
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
      case 'androidDownloadedContent':
        if (instance != null &&
            instance._androidDownloadedStreamController != null &&
            !instance._androidDownloadedStreamController.isClosed) {
          final content = AndroidDownloadedContent.fromJson(
              (call.arguments as Map<dynamic, dynamic>));

          instance._androidDownloadedStreamController.add(content);
        }

        break;

      default:
        _log('Unknown method ${call.method} ');
    }
  }
}
