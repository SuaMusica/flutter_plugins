import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smads/pre_roll.dart';
import 'package:smads/pre_roll_controller.dart';
import 'package:smads/pre_roll_events.dart';

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

  PreRoll? _preRoll;
  PreRollController? _preRollController;
  PreRollController get preRollController =>
      _preRollController ??= PreRollController(preRollListener);
  bool _isPreRollReady = false;
  final Map<String, String> keyValues = {};
  String _duration = '00:00', _position = '00:00';
  @override
  void initState() {
    super.initState();
    preRollLoad();
  }

  void preRollListener(PreRollEvent event, Map<String, dynamic> args) {
    if (event != PreRollEvent.AD_PROGRESS) {
      debugPrint('Pre Roll Event: $event');
    }
    debugPrint(event.toShortString());

    switch (event) {
      case PreRollEvent.LOADED:
        setState(() {
          _isPreRollReady = true;
        });
        break;
      case PreRollEvent.PAUSED:
      case PreRollEvent.STARTED:
      case PreRollEvent.RESUMED:
        // preRollPlaying(event != PreRollEvent.PAUSED);
        break;
      case PreRollEvent.ALL_ADS_COMPLETED:
      case PreRollEvent.COMPLETED:
        preRollEnd();
        break;
      case PreRollEvent.AD_PROGRESS:
        setState(() {
          _duration = args['duration'] as String;
          _position = args['position'] as String;
        });

        break;
      default:
        return;
    }
  }

  void preRollEnd() {
    setState(() {
      _isPreRollReady = false;
      _duration = '00:00';
      _position = '00:00';
    });
  }

  Future<void> preRollStart() async {
    final screenStatus = await preRollController.screenStatus;
    if (_isPreRollReady) {
      setState(() {
        _duration = '00:00';
        _position = '00:00';
      });
      if (screenStatus != 1) {
        preRollController.play();
      }
    } else {
      preRollLoad();
    }
  }

  Future<Map<String, String>> getKeyValues() async {
    keyValues['age'] = '0';
    keyValues['gender'] = '-1';
    keyValues['version'] = '123';

    final screenStatus = await preRollController.screenStatus;
    final url =
        "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=";

    keyValues['__URL__'] = screenStatus != 1
        ? url.replaceAll('ad_type=audio_video', 'ad_type=audio')
        : url;

    return keyValues;
  }

  void preRollLoad() {
    _isPreRollReady = false;
    preRollController.dispose();

    getKeyValues().then((targetMap) {
      _preRoll = PreRoll(
        controller: preRollController,
      );
      preRollController.load(targetMap);
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text('Preroll is Ready? $_isPreRollReady'),
              AspectRatio(
                aspectRatio: 640 / 480,
                child: _isPreRollReady && _preRoll != null
                    ? _preRoll!
                    : Container(
                        color: Colors.pink,
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(_position),
                  Text(_duration),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MaterialButton(
                    color: Colors.blue,
                    onPressed: () {
                      preRollController.pause();
                    },
                    child: Text(
                      'Pause',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  MaterialButton(
                    color: Colors.blue,
                    onPressed: () {
                      preRollController.play();
                    },
                    child: Text(
                      'Play',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
