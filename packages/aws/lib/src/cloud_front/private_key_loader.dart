import 'package:rsa_pkcs/rsa_pkcs.dart';

abstract class PrivateKeyLoader {
  Future<RSAPrivateKey> load();
}