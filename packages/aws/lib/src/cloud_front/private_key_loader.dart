import 'package:flutter/services.dart';
import 'package:rsa_pkcs/rsa_pkcs.dart';

class PrivateKeyLoader {
  static Future<RSAPrivateKey> loadPrivateKey(String privateKeyPath) async {
    String pem = await rootBundle.loadString(privateKeyPath);
    final RSAPKCSParser parser = RSAPKCSParser();
    final RSAKeyPair pair = parser.parsePEM(pem);
    return pair.private;
  }
}

class PublicKeyLoader {
  static Future<RSAPublicKey> loadPublicKey(String publicKeyPath) async {
    String pem = await rootBundle.loadString(publicKeyPath);
    final RSAPKCSParser parser = RSAPKCSParser();
    final RSAKeyPair pair = parser.parsePEM(pem);
    return pair.public;
  }
}
