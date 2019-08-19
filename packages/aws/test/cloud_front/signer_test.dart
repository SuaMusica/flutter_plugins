import 'dart:io';

import 'package:aws/src/cloud_front/private_key_loader.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aws/aws.dart';
import 'package:rsa_pkcs/rsa_pkcs.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets('Simple Cookie Test', (WidgetTester tester) async {
    final signer = Signer(privateKeyPath: 'assets/loading_images.pem');
    const resourceUrl = "https://*.suamusica.com.br/*";
    RSAPrivateKey privateKey = await PrivateKeyLoader.loadPrivateKey();
    const keyPairId = "APKAIORXYQDPHCKBDXYQ";
    DateTime expiresOn = DateTime.now().add(Duration(hours: 12));
    CookiesForCustomPolicy cookies = await signer.getCookiesForCustomPolicy(
        resourceUrl, privateKey, keyPairId, expiresOn, null, null);

    final cookie = "${cookies.policy.key}=${cookies.policy.value}; ${cookies.signature.key}=${cookies.signature.value}; ${cookies.keyPairId.key}=${cookies.keyPairId.value}; ";

    print(cookie);

    http.Client().get(
        'https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3',
        headers: {'Cookie': cookie})
        .then((http.Response r) { 
          print(r.statusCode); 
          print(r.body); 
        });
  });
}
