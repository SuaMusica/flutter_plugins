import 'package:flutter/material.dart';
import 'dart:async';

import 'package:smads/smads.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ads = SMAds();

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
                  await ads.load({"gender": "femela"});
                }
              ),
              MaterialButton(
                child: Text('Play'),
                color: Colors.deepOrangeAccent,
                onPressed: () async {
                  await ads.play();
                }
              )              
            ],
          ),
        ),
      ),
    );
  }
}
