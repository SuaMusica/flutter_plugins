import 'package:smaws/src/cloud_front/entry.dart';
import 'package:smaws/src/cloud_front/signed_cookie.dart';

class CookiesForCustomPolicy extends SignedCookies {
  final Entry<String, String> policy;
  final Entry<String, String> keyPairId;
  final Entry<String, String> signature;

  CookiesForCustomPolicy({
    required DateTime expires,
    int? difference,
    required this.policy,
    required this.keyPairId,
    required this.signature,
  }) : super(difference, expires);

  String toHeaders() =>
      "${this.policy.key}=${this.policy.value};${this.signature.key}=${this.signature.value};${this.keyPairId.key}=${this.keyPairId.value}";
  String toURL() =>
      "?Expires=${this.expires.millisecondsSinceEpoch ~/ 1000}&Signature=${this.signature.value}&Key-Pair-Id=${this.keyPairId.value}";
}
