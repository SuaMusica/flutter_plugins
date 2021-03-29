import 'package:equalizer/equalizer_controller.dart';
import 'package:equalizer/equalizer_widget.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final EqualizerController equalizerController =
      EqualizerController(audioSessionId: 0);

  @override
  void initState() {
    equalizerController.init(0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Equalizer example'),
        ),
        body: EqualizerWidget(
          equalizerController,
          titleEnabled: Text("Habilitado"),
          titleDisabled: Text("Desabilitado"),
          onSwitch: (value) {
            debugPrint("Test trackSwitch $value");
          },
          onSelectType: (value) {
            debugPrint("Test trackSelectType $value");
          },
        ),
      ),
    );
  }
}
