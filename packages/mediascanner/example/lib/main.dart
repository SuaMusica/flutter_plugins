import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mediascanner/media_scanner.dart';
import 'package:mediascanner/model/media_scan_params.dart';
import 'package:mediascanner/model/media_type.dart';
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

  @override
  void initState() {
    super.initState();
    scanMedias();
  }

  Future<void> scanMedias() async {
    await Permission.storage.request();
    MediaScanner.instance
        .scan(MediaScanParams(MediaType.audio, [".mp3", ".wav"], "", 0));
  }

  int totalMediaScanned = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Running on: $_platformVersion\n'),
              StreamBuilder<ScannedMedia>(
                  stream: MediaScanner.instance.onScannedMediaStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError || !snapshot.hasData)
                      return Container();
                    totalMediaScanned++;
                    return Text('Total Media Scanned: $totalMediaScanned\n');
                  }),
              StreamBuilder<List<ScannedMedia>>(
                stream: MediaScanner.instance.onListScannedMediaStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData)
                    return Container();

                  return Expanded(
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
                          snapshot.data!.length,
                          (index) =>
                              _getScannedMediaWidget(snapshot.data![index])),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getScannedMediaWidget(ScannedMedia data) {
    return GridTile(
      header: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _getTile("Music Path", data.path),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _getTile("Track", data.track!),
            _getTile("AlbumId", data.albumId.toString()),
            _getTile("Album", data.album),
            _getTile("Title", data.title),
            _getTile("Artist", data.artist),
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

  Widget _getTile(String label, String value) {
    return Text(
      "($label) $value",
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
