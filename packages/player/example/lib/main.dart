import 'package:flutter/material.dart';
import 'package:suamusica_player_example/sm_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Player example app'),
        ),
        body: Material(
          child: SMPlayer(),
        ),
      ),
    );
  }
}
