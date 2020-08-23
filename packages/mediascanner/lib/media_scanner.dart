import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mediascanner/model/media_scan_params.dart';
import 'package:mediascanner/model/scanned_media.dart';

const ON_MEDIA_SCANNED_METHOD = "onMediaScanned";

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

  final StreamController<ScannedMedia> _controller =
      StreamController<ScannedMedia>.broadcast();

  Stream<ScannedMedia> get onScannedMediaStream => _controller.stream;

  dispose() async {
    _controller.close();
  }

  Future<bool> scan(MediaScanParams params) async {
    final result = await _channel.invokeMethod("scan_media", params.toChannelParams());
    return result > 0;
  }

  static Future<void> _callbackHandler(MethodCall call) async {
    switch (call.method) {
      case ON_MEDIA_SCANNED_METHOD:
        _onMediaScanned(call.arguments);
        break;
      default:
        return;
    }
  }

  static void _onMediaScanned(arguments) {
    print("_onMediaScanned($arguments)");
    final scannedMedia = ScannedMedia.fromMap(arguments as Map<dynamic, dynamic>);
    instance._controller
        .add(scannedMedia);
  }
}
