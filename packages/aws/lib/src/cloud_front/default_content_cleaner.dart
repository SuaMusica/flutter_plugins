import 'dart:convert';
import 'dart:typed_data';

import 'package:aws/src/cloud_front/content_cleaner.dart';

class DefaultContentCleaner implements ContentCleaner {
  String makeBytesUrlSafe(Uint8List input) {
    String encoded = base64.encode(input);
    StringBuffer result = StringBuffer();
    for (int i = 0; i < encoded.length; i++) {
      switch (encoded[i]) {
        case '+':
          result.write('-');
          continue;
        case '=':
          result.write('_');
          continue;
        case '/':
          result.write('~');
          continue;
        default:
          result.write(encoded[i]);
          continue;
      }
    }
    return result.toString();
  }
}
