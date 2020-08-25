import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mediascanner/model/media_scan_params.dart';
import 'package:mediascanner/model/scanned_media.dart';

const ON_MEDIA_SCANNED_METHOD = "onMediaScanned";
const ON_ALL_MEDIA_SCANNED_METHOD = "onAllMediaScanned";

class MediaScanner {
  MediaScanner._();

  static MediaScanner _instance;

  static MediaScanner get instance {
    if (_instance == null) {
      _instance = MediaScanner._();
    }
    return _instance;
  }

  static final MethodChannel _channel = const MethodChannel('MediaScanner')
    ..setMethodCallHandler(_callbackHandler);

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  final StreamController<ScannedMedia> _onScannedMediaStreamController =
      StreamController<ScannedMedia>.broadcast();

  Stream<ScannedMedia> get onScannedMediaStream =>
      _onScannedMediaStreamController.stream;

  final StreamController<List<ScannedMedia>>
      _onListScannedMediaStreamController =
      StreamController<List<ScannedMedia>>.broadcast();

  Stream<List<ScannedMedia>> get onListScannedMediaStream =>
      _onListScannedMediaStreamController.stream;

  dispose() async {
    _onScannedMediaStreamController.close();
    _onListScannedMediaStreamController.close();
  }

  Future<bool> scan(MediaScanParams params) async {
    final result =
        await _channel.invokeMethod("scan_media", params.toChannelParams());
    return result > 0;
  }

  static Future<void> _callbackHandler(MethodCall call) async {
    switch (call.method) {
      case ON_MEDIA_SCANNED_METHOD:
        _onMediaScanned(call.arguments);
        break;
      case ON_ALL_MEDIA_SCANNED_METHOD:
        _onAllMediaScanned(call.arguments);
        break;
      default:
        return;
    }
  }

  static void _onMediaScanned(arguments) {
    print("_onMediaScanned($arguments)");
    final scannedMedia =
        ScannedMedia.fromMap(arguments as Map<dynamic, dynamic>);
    instance._onScannedMediaStreamController.add(scannedMedia);
  }

  static void _onAllMediaScanned(arguments) {
    print("_onAllMediaScanned($arguments)");
    final scannedMediaList =
        ScannedMedia.fromList(arguments as List<dynamic>);
    instance._onListScannedMediaStreamController.add(scannedMediaList);
  }
}
