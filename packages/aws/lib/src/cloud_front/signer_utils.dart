import 'dart:convert';

class SignerUtils {
  static String makeBytesUrlSafe(String input) {
    String encoded = base64.encode(utf8.encode(input));
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
