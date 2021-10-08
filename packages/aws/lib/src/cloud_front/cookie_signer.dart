import 'dart:async';
import 'dart:typed_data';
import 'package:smaws/src/cloud_front/cookies_for_custom_policy.dart';
import 'package:smaws/src/cloud_front/default_content_cleaner.dart';
import 'package:smaws/src/cloud_front/default_private_key_loader.dart';
import 'package:smaws/src/cloud_front/entry.dart';
import 'package:smaws/src/cloud_front/policy_builder.dart';
import 'package:smaws/src/cloud_front/custom_policy_builder.dart';
import 'package:smaws/src/cloud_front/content_cleaner.dart';
import 'package:smaws/src/cloud_front/private_key_loader.dart';
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

  CookieSigner(
    privateKeyPathOrLoader,
    this.policyBuilder,
    this.contentCleaner, {
    bool isDirect = false,
  }) : privateKeyLoader = privateKeyPathOrLoader is String
            ? DefaultPrivateKeyLoader(privateKeyPathOrLoader, isDirect)
            : privateKeyPathOrLoader;

  factory CookieSigner.from(
    String privateKeyPath, {
    bool isDirect = false,
  }) =>
      CookieSigner(
        privateKeyPath,
        CustomPolicyBuilder(),
        DefaultContentCleaner(),
        isDirect: isDirect,
      );

  Future<CookiesForCustomPolicy> getCookiesForCustomPolicy({
    required String resourceUrlOrPath,
    required String keyPairId,
    int? difference,
    required DateTime expiresOn,
    DateTime? activeFrom,
    String? ipRange,
  }) async {
    final String policy =
        _buildPolicy(resourceUrlOrPath, expiresOn, activeFrom, ipRange);

    pointycastle.RSASignature signature =
        await _signWithSha1RSA(Uint8List.fromList(policy.codeUnits));

    String urlSafePolicy =
        _makeBytesUrlSafe(Uint8List.fromList(policy.codeUnits));

    String urlSafeSignature = _makeBytesUrlSafe(signature.bytes);

    return CookiesForCustomPolicy(
      expires: expiresOn,
      difference: difference ?? 0,
      policy: Entry(PolicyKey, urlSafePolicy),
      keyPairId: Entry(KeyPairIdKey, keyPairId),
      signature: Entry(SignatureKey, urlSafeSignature),
    );
  }

  _buildPolicy(String resourceUrlOrPath, DateTime expiresOn,
          DateTime? activeFrom, String? ipRange) =>
      this
          .policyBuilder
          .build(resourceUrlOrPath, expiresOn, activeFrom, ipRange);

  Future<pointycastle.RSASignature> _signWithSha1RSA(
      Uint8List dataToSign) async {
    var signer = pointycastle.Signer("SHA-1/RSA");
    var privateKey = await privateKeyLoader.load();
    if (privateKey == null) {
      throw NullThrownError();
    }
    var privk = pointycastle.RSAPrivateKey(privateKey.modulus,
        privateKey.privateExponent, privateKey.prime1, privateKey.prime2);

    CipherParameters privParams = pointycastle.ParametersWithRandom(
        pointycastle.PrivateKeyParameter<pointycastle.RSAPrivateKey>(privk),
        FortunaRandom());

    signer.reset();
    signer.init(true, privParams);
    return signer.generateSignature(dataToSign) as pointycastle.RSASignature;
  }

  String _makeBytesUrlSafe(Uint8List content) =>
      contentCleaner.makeBytesUrlSafe(content);
}
