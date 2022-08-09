import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smads/pre_roll.dart';
import 'package:smads/pre_roll_controller.dart';
import 'package:smads/pre_roll_events.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PreRoll? _preRoll;
  PreRollController? _preRollController;
  PreRollController get preRollController =>
      _preRollController ??= PreRollController(preRollListener);
  bool _isPreRollReady = false, _isIosReady = false;
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
    switch (event) {
      case PreRollEvent.IOS_READY:
        setState(() {
          _isIosReady = true;
        });
        break;
      case PreRollEvent.LOADED:
        setState(() {
          _isPreRollReady = true;
          _preRollController?.play();
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
      _isIosReady = false;
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
        // "https://cmod424.live.streamtheworld.com/ondemand/ars?type=preroll&version=1.5.1&fmt=vast&stid=103013&banners=300x250&dist=testeapp";
        "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=";

    keyValues['__URL__'] = screenStatus != 1
        ? url.replaceAll('ad_type=audio_video', 'ad_type=audio')
        : url;

    return keyValues;
  }

  void preRollLoad() {
    _isPreRollReady = false;
    _isIosReady = false;
    preRollController.dispose();

    getKeyValues().then((targetMap) {
      _preRoll = PreRoll(
        maxHeight: 480,
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
        body: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text('Preroll is Ready? $_isPreRollReady'),
                (_isPreRollReady || _isIosReady) && _preRoll != null
                    ? _preRoll!
                    : Container(),
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
      ),
    );
  }
}
