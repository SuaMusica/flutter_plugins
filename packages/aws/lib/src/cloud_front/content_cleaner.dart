import 'dart:typed_data';

abstract class ContentCleaner {
  String makeBytesUrlSafe(Uint8List input);
}
