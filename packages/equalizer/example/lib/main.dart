import 'package:equalizer/equalizer_controller.dart';
import 'package:equalizer/equalizer_widget.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
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
          title: const Text('Equalizer Example App'),
          centerTitle: true,
        ),
        body: ListView(
          children: [
            Equalizer(
              equalizerController: equalizerController,
            ),
            Divider(),
            EqualizerWidget(
              equalizerController,
              titleEnabled: Text('Habilitado'),
              titleDisabled: Text('Desabilitado'),
              onSwitch: (value) => debugPrint('Test trackSwitch $value'),
              onSelectType: (value) =>
                  debugPrint('Test trackSelectType $value'),
            ),
          ],
        ),
      ),
    );
  }
}

class Equalizer extends StatefulWidget {
  const Equalizer({
    super.key,
    required this.equalizerController,
  });

  final EqualizerController equalizerController;

  @override
  State<Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer> {
  Future<bool?> hasEqualizer = Future.value(false);

  @override
  void initState() {
    super.initState();
    hasEqualizer = widget.equalizerController.deviceHasEqualizer();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: hasEqualizer,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'This device ${snapshot.data ? 'has' : 'does not have'} equalizer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
