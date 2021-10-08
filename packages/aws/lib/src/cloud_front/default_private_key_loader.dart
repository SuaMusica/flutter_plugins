import 'package:smaws/src/cloud_front/private_key_loader.dart';
import 'package:flutter/services.dart';
import 'package:rsa_pkcs/rsa_pkcs.dart';

class DefaultPrivateKeyLoader implements PrivateKeyLoader {
  final String privateKeyPath;
  final bool isKey;
  DefaultPrivateKeyLoader(this.privateKeyPath, [this.isKey = false]);

  Future<RSAPrivateKey?> load() async {
    String pem =
        isKey ? privateKeyPath : await rootBundle.loadString(privateKeyPath);
    final RSAPKCSParser parser = RSAPKCSParser();
    final RSAKeyPair pair = parser.parsePEM(pem);
    return pair.private;
  }
}
