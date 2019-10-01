import 'package:smaws/src/cloud_front/entry.dart';
import 'package:smaws/src/cloud_front/signed_cookie.dart';

class CookiesForCustomPolicy extends SignedCookies {
  final Entry<String, String> policy;
  final Entry<String, String> keyPairId;
  final Entry<String, String> signature;

  CookiesForCustomPolicy(
      DateTime expires, this.policy, this.keyPairId, this.signature)
      : super(expires);
}