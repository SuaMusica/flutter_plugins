import 'dart:developer';

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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Equalizer example'),
        ),
        body: Equalizer(
          equalizerController: equalizerController,
        ),
      ),
    );
  }
}

class Equalizer extends StatelessWidget {
  const Equalizer({
    Key? key,
    required this.equalizerController,
  }) : super(key: key);

  final EqualizerController equalizerController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: false,
      future: equalizerController.deviceHasEqualizer(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        log('snapshot.data: ${snapshot.data}');
        return Center(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Equalizer example'),
                    ),
                    body: EqualizerWidget(
                      equalizerController,
                      titleEnabled: Text('Habilitado'),
                      titleDisabled: Text('Desabilitado'),
                      onSwitch: (value) =>
                          debugPrint('Test trackSwitch $value'),
                      onSelectType: (value) =>
                          debugPrint('Test trackSelectType $value'),
                    ),
                  ),
                ),
              );
            },
            child: Text(
              'O dispositivo ${snapshot.data ? 'tem' : 'não tem'} equalizador',
            ),
          ),
        );
      },
    );
  }
}
