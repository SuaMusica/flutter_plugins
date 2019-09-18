import 'dart:async';
import 'dart:typed_data';
import 'package:aws/src/cloud_front/cookies_for_custom_policy.dart';
import 'package:aws/src/cloud_front/default_content_cleaner.dart';
import 'package:aws/src/cloud_front/default_private_key_loader.dart';
import 'package:aws/src/cloud_front/entry.dart';
import 'package:aws/src/cloud_front/policy_builder.dart';
import 'package:aws/src/cloud_front/custom_policy_builder.dart';
import 'package:aws/src/cloud_front/content_cleaner.dart';
import 'package:aws/src/cloud_front/private_key_loader.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/pointycastle.dart' as pointycastle;

class CookieSigner {
  final PrivateKeyLoader privateKeyLoader;
  final PolicyBuilder policyBuilder;
  final ContentCleaner contentCleaner;

  static const ExpiresKey = 'CloudFront-Expires';
  static const String SignatureKey = 'CloudFront-Signature';
  static const String PolicyKey = 'CloudFront-Policy';
  static const String KeyPairIdKey = 'CloudFront-Key-Pair-Id';

  CookieSigner(privateKeyPathOrLoader, this.policyBuilder, this.contentCleaner)
      : privateKeyLoader = privateKeyPathOrLoader is String
            ? DefaultPrivateKeyLoader(privateKeyPathOrLoader)
            : privateKeyPathOrLoader;

  factory CookieSigner.from(String privateKeyPath) => CookieSigner(
      privateKeyPath, CustomPolicyBuilder(), DefaultContentCleaner());

  Future<CookiesForCustomPolicy> getCookiesForCustomPolicy(
      String resourceUrlOrPath,
      String keyPairId,
      DateTime expiresOn,
      DateTime activeFrom,
      String ipRange) async {
    ArgumentError.checkNotNull(resourceUrlOrPath);
    ArgumentError.checkNotNull(keyPairId);
    ArgumentError.checkNotNull(expiresOn);

    final String policy =
        _buildPolicy(resourceUrlOrPath, expiresOn, activeFrom, ipRange);

    pointycastle.RSASignature signature =
        await _signWithSha1RSA(Uint8List.fromList(policy.codeUnits));

    String urlSafePolicy =
        _makeBytesUrlSafe(Uint8List.fromList(policy.codeUnits));

    String urlSafeSignature = _makeBytesUrlSafe(signature.bytes);

    return CookiesForCustomPolicy(
      expiresOn,
      Entry(PolicyKey, urlSafePolicy),
      Entry(KeyPairIdKey, keyPairId),
      Entry(SignatureKey, urlSafeSignature),
    );
  }

  _buildPolicy(String resourceUrlOrPath, DateTime expiresOn,
          DateTime activeFrom, String ipRange) =>
      this
          .policyBuilder
          .build(resourceUrlOrPath, expiresOn, activeFrom, ipRange);

  Future<Signature> _signWithSha1RSA(Uint8List dataToSign) async {
    var signer = pointycastle.Signer("SHA-1/RSA");
    var privateKey = await privateKeyLoader.load();

    var privk = pointycastle.RSAPrivateKey(privateKey.modulus,
        privateKey.privateExponent, privateKey.prime1, privateKey.prime2);

    CipherParameters privParams = pointycastle.ParametersWithRandom(
        pointycastle.PrivateKeyParameter<pointycastle.RSAPrivateKey>(privk),
        FortunaRandom());

    signer.reset();
    signer.init(true, privParams);
    return signer.generateSignature(dataToSign);
  }

  String _makeBytesUrlSafe(Uint8List content) => contentCleaner.makeBytesUrlSafe(content);
}
