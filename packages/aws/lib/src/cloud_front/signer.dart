import 'dart:async';
import 'dart:typed_data';
import 'package:aws/src/cloud_front/cookies_for_custom_policy.dart';
import 'package:aws/src/cloud_front/entry.dart';
import 'package:aws/src/cloud_front/private_key_loader.dart';
import 'package:aws/src/cloud_front/signer_utils.dart';
import 'package:rsa_pkcs/rsa_pkcs.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/pointycastle.dart' as pointycastle;

class Signer {
  final privateKeyPath;

  static const ExpiresKey = 'CloudFront-Expires';
  static const String SignatureKey = 'CloudFront-Signature';
  static const String PolicyKey = 'CloudFront-Policy';
  static const String KeyPairIdKey = 'CloudFront-Key-Pair-Id';

  Signer({this.privateKeyPath});

  Future<CookiesForCustomPolicy> getCookiesForCustomPolicy(
      String resourceUrlOrPath,
      RSAPrivateKey privateKey,
      String keyPairId,
      DateTime expiresOn,
      DateTime activeFrom,
      String ipRange) async {
    final String policy =
        _buildCustomPolicy(resourceUrlOrPath, expiresOn, activeFrom, ipRange);

    Signature signature = await _signWithSha1RSA(
        Uint8List.fromList(policy.codeUnits), privateKey);

    String urlSafePolicy = SignerUtils.makeBytesUrlSafe(policy);

    String urlSafeSignature =
        SignerUtils.makeBytesUrlSafe(signature.toString());

    return CookiesForCustomPolicy(
      expiresOn, 
      Entry(PolicyKey, urlSafePolicy),
      Entry(KeyPairIdKey, keyPairId),
      Entry(SignatureKey, urlSafeSignature),
    );
  }

  String _buildCustomPolicy(String resourceUrlOrPath, DateTime expiresOn,
      DateTime activeFrom, String ipRange) {
    return "{\"Statement\": [{" +
        "\"Resource\":\"" +
        resourceUrlOrPath +
        "\"" +
        ",\"Condition\":{" +
        "\"DateLessThan\":{\"AWS:EpochTime\":" +
        Duration(milliseconds: expiresOn.millisecondsSinceEpoch)
            .inSeconds
            .toString() +
        "}" +
        (ipRange == null
            ? ""
            : ",\"IpAddress\":{\"AWS:SourceIp\":\"" + ipRange + "\"}") +
        (activeFrom == null
            ? ""
            : ",\"DateGreaterThan\":{\"AWS:EpochTime\":" +
                Duration(milliseconds: activeFrom.millisecondsSinceEpoch)
                    .inSeconds
                    .toString() +
                "}") +
        "}}]}";
  }

  static Future<Signature> _signWithSha1RSA(
      Uint8List dataToSign, RSAPrivateKey privateKey) async {
    var signer = new pointycastle.Signer("SHA-1/RSA");
    var privateKey = await PrivateKeyLoader.loadPrivateKey();
    var privk = new pointycastle.RSAPrivateKey(privateKey.modulus,
        privateKey.privateExponent, privateKey.prime1, privateKey.prime2);
    CipherParameters privParams = new pointycastle.ParametersWithRandom(
        new pointycastle.PrivateKeyParameter<pointycastle.RSAPrivateKey>(privk),
        new FortunaRandom());
    signer.reset();
    signer.init(true, privParams);
    return signer.generateSignature(dataToSign);
  }
}
