import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mediascanner/media_scanner.dart';
import 'package:mediascanner/model/media_scan_params.dart';
import 'package:mediascanner/model/scanned_media.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _media = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    scanMedias();
  }

  Future<void> scanMedias() async {
    await Permission.storage.request();
    MediaScanner.instance.scan(MediaScanParams(MediaType.audio, [".mp3", ".wav"]));
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    String media;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await MediaScanner.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
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
            children: [
              Text('Running on: $_platformVersion\n'),
              StreamBuilder<ScannedMedia>(
                stream: MediaScanner.instance.onScannedMediaStream,
                builder: (context, snapshot) {

                  if (snapshot.hasError || !snapshot.hasData)
                    return Container();

                  return Text('Scanned Media: ${snapshot.data}\n');
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
