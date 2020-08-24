import 'package:smaws/src/cloud_front/entry.dart';
import 'package:smaws/src/cloud_front/signed_cookie.dart';

class CookiesForCustomPolicy extends SignedCookies {
  final Entry<String, String> policy;
  final Entry<String, String> keyPairId;
  final Entry<String, String> signature;

  CookiesForCustomPolicy({
    DateTime expires,
    int difference,
    this.policy,
    this.keyPairId,
    this.signature,
  }) : super(difference, expires);

  String toHeaders() =>
      "${this.policy.key}=${this.policy.value};${this.signature.key}=${this.signature.value};${this.keyPairId.key}=${this.keyPairId.value}";
}
