import 'package:flutter_test/flutter_test.dart';
import 'package:smaws/aws.dart';

void main() {
  testWidgets('Cookie Signer Test Suit', (WidgetTester tester) async {
    final signer = CookieSigner.from('assets/pk-APKAIORXYQDPHCKBDXYQ.pem');
    const resourceUrl = 'https://*.suamusica.com.br*';
    const keyPairId = "APKAIORXYQDPHCKBDXYQ";
    DateTime expiresOn = DateTime.now().add(Duration(hours: 12));

    CookiesForCustomPolicy cookies = await signer.getCookiesForCustomPolicy(
      resourceUrlOrPath: resourceUrl,
      keyPairId: keyPairId,
      expiresOn: expiresOn,
    );

    final cookie =
        "${cookies.policy.key}=${cookies.policy.value};${cookies.signature.key}=${cookies.signature.value};${cookies.keyPairId.key}=${cookies.keyPairId.value};";
    final resource =
        'https://stream.suamusica.com.br/373377/2238511/stream/02+O+Bebe.m3u8';
    String curl =
        "curl -v '$resource' --cookie \"$cookie\" --output ./test.mp3";
    print(curl);
  });
}
