import 'package:flutter_test/flutter_test.dart';
import 'package:aws/aws.dart';

void main() {
  testWidgets('Cookie Signer Test Suit', (WidgetTester tester) async {
    final signer = CookieSigner.from('assets/pk-APKAIORXYQDPHCKBDXYQ.pem');
    const resourceUrl = 'https://android.suamusica.com.br*';
    const keyPairId = "APKAIORXYQDPHCKBDXYQ";
    DateTime expiresOn = DateTime.now().add(Duration(hours: 12));

    CookiesForCustomPolicy cookies = await signer.getCookiesForCustomPolicy(
        resourceUrl, keyPairId, expiresOn, null, null);

    final cookie =
        "${cookies.policy.key}=${cookies.policy.value};${cookies.signature.key}=${cookies.signature.value};${cookies.keyPairId.key}=${cookies.keyPairId.value};";
    final resource =
        'https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3';
    String curl =
        "curl -v '$resource' --cookie \"$cookie\" --output ./test.mp3";
    print(curl);
  });
}
