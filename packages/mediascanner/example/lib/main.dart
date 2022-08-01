import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediascanner/media_scanner.dart';
import 'package:mediascanner/model/scanned_media.dart';
import 'package:mediascanner_example/bloc/scan_bloc.dart';
import 'package:mediascanner_example/db/drift/drift_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ScanBloc scanBloc;
  @override
  void initState() {
    super.initState();
    initPlatformState();
    scanBloc = ScanBloc()
      ..add(
        CreateDB(
          exampleDatabase: ExampleDatabase.instance,
        ),
      );
  }

  int totalMediaScanned = 0;

  Future<void> initPlatformState() async {
    MediaScanner.instance.onListScannedMediaStream.listen(
      (List<ScannedMedia> event) {
        scanBloc.add(
          AllMediaScanned(
            listMedias: event,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: BlocBuilder<ScanBloc, ScanState>(
            bloc: scanBloc,
            builder: (context, state) {
              if (state is Scanned) {
                return Column(
                  children: [
                    Text('Medias: ${state.medias.length}\n'),
                    Expanded(
                      child: GridView.count(
                        physics: BouncingScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        primary: false,
                        padding: const EdgeInsets.all(2),
                        children: List.generate(
                          state.medias.length,
                          (index) => _getScannedMediaWidget(
                            state.medias[index],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else
                return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }

  Widget _getScannedMediaWidget(ScannedMedia data) {
    return GridTile(
      header: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _getTile(value: data.title, fontSize: 15),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _getTile(label: "ID", value: data.mediaId.toString()),
            _getTile(label: "Track", value: data.track!),
            _getTile(label: "AlbumId", value: data.albumId.toString()),
            _getTile(label: "Album", value: data.album),
            _getTile(label: "Artist", value: data.artist),
            _getTile(label: "Music Path", value: data.path)
          ],
        ),
      ),
      child: Card(
        child: Opacity(
          opacity: 0.3,
          child: data.albumCoverPath!.isEmpty
              ? Container()
              : Image.file(
                  File(data.albumCoverPath!),
                  fit: BoxFit.fill,
                ),
        ),
      ),
    );
  }

  Widget _getTile({
    String? label,
    required String value,
    double fontSize = 9.0,
  }) {
    final text = label == null ? '' : label;
    return Text(
      '$text $value',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
