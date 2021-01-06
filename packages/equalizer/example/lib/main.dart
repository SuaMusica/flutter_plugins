import 'package:equalizer/equalizer_controller.dart';
import 'package:equalizer/equalizer_widget.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final EqualizerController equalizerController = EqualizerController();

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
        ),
        // body: Column(
        //   children: [
        //     FutureBuilder<bool>(
        //       future: Equalizer.deviceHasEqualizer(0),
        //       builder: (context, snapshot) => snapshot.hasData
        //           ? Center(
        //         child: Text(
        //           "Device does ${snapshot.data ? '' : 'not '}support equalizer ",
        //         ),
        //       )
        //           : Container(),
        //     ),
        //     EqualizerWidget(),
        //   ],
        // ),
      ),
    );
  }
}
