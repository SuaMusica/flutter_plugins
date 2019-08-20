import 'package:aws/aws.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:suamusica_player/player.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Player _player;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      var player = Player(cookieSigner);

      if (!mounted) return;

      setState(() {
        _player = player;
      });
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
  }

  Future<String> cookieSigner() async {
    final signer = CookieSigner.from('assets/pk-APKAIORXYQDPHCKBDXYQ.pem');
    const resource = 'https://*.suamusica.com.br*';
    const keyPairId = "APKAIORXYQDPHCKBDXYQ";
    DateTime expiresOn = DateTime.now().add(Duration(hours: 12));

    final cookies = await signer.getCookiesForCustomPolicy(
        resource, keyPairId, expiresOn, null, null);

    final cookie =
        "${cookies.policy.key}=${cookies.policy.value};${cookies.signature.key}=${cookies.signature.value};${cookies.keyPairId.key}=${cookies.keyPairId.value}";
    return cookie;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Material(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                MaterialButton(
                  padding: const EdgeInsets.all(8.0),
                  textColor: Colors.white,
                  color: Colors.blue,
                  onPressed: () {
                    final media = Media(
                        id: "31196178",
                        name: "O Bebe",
                        url:
                            "https://android.suamusica.com.br/373377/2238511/02+O+Bebe.mp3",
                        coverUrl:
                            "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
                        author: "Xand Avião",
                        isLocal: false,
                        isVerified: true,
                        shareUrl: "");
                    _player.play(media, stayAwake: true, volume: 2.0);
                  },
                  child: const Text(
                    'Play .mp3',
                  ),
                ),
                const SizedBox(height: 30),
                MaterialButton(
                  padding: const EdgeInsets.all(8.0),
                  textColor: Colors.white,
                  color: Colors.blue,
                  onPressed: () {
                    final media = Media(
                        id: "31196178",
                        name: "O Bebe",
                        url:
                            "https://stream.suamusica.com.br/373377/2238511/stream/02+O+Bebe.m3u8",
                        coverUrl:
                            "https://images.suamusica.com.br/5hxcfuN3q0lXbSiWXaEwgRS55gQ=/240x240/373377/2238511/cd_cover.jpeg",
                        author: "Xand Avião",
                        isLocal: false,
                        isVerified: true,
                        shareUrl: "");
                    _player.play(media, stayAwake: true, volume: 2.0);
                  },
                  child: const Text(
                    'Play .m3u8',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
