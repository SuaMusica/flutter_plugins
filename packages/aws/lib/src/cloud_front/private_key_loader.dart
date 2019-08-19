import 'package:flutter/services.dart';
import 'package:rsa_pkcs/rsa_pkcs.dart';

class PrivateKeyLoader {
  static Future<RSAPrivateKey> loadPrivateKey() async {
    String pem = await rootBundle.loadString('assets/loading_images.pem');
    final RSAPKCSParser parser = RSAPKCSParser();
    final RSAKeyPair pair = parser.parsePEM(pem);
    return pair.private;
  }
}