import 'dart:async';

import 'package:flutter/services.dart';
import 'package:migration/downloaded_content.dart';

class Migration {
  Migration._();

  static Migration _instance;

  static Migration get instance {
    return _instance ??= Migration._();
  }

  static const MethodChannel _channel = const MethodChannel('migration');

  final StreamController<List<DownloadedContent>> _streamController =
      StreamController<List<DownloadedContent>>.broadcast();

  Stream<List<DownloadedContent>> get downloadedContent =>
      _streamController.stream;

  void getLegacyDownloadContent() async {
    final List<dynamic> result =
        await _channel.invokeMethod('getLegacyDownloadedContent');

    final content = result
        .where((item) => item is Map<String, dynamic>)
        .map(
          (item) => DownloadedContent.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    _streamController.add(content);
  }
}
