import 'package:flutter/material.dart';
import 'dart:async';

import 'package:smads/smads.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ads = SMAds(
    adUrl:
        "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=",
    contentUrl: "https://assets.suamusica.com.br/video/virgula.mp3",
  );

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    ads.onEvent.listen((e) {
      print("Got an AdEvent: ${e.toString()}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              MaterialButton(
                  child: Text('Load'),
                  color: Colors.blueAccent,
                  onPressed: () async {
                    await ads.load({"gender": "female", "age": 45}, () {
                      print("Ad display have been completed!");
                    });
                  })
            ],
          ),
        ),
      ),
    );
  }
}