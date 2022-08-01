import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediascanner/media_scanner.dart';
import 'package:mediascanner/model/media_scan_params.dart';
import 'package:mediascanner/model/media_type.dart';
import 'package:mediascanner/model/scanned_media.dart';
import 'package:mediascanner_example/db/drift/drift_database.dart';
import 'package:permission_handler/permission_handler.dart';

part 'scan_event.dart';
part 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc() : super(ScanInitial()) {
    on<StartScanner>(_onScan);
    on<CreateDB>(_onCreateDB);
    on<AllMediaScanned>(_allMediaScanned);
  }

  FutureOr<void> _onScan(StartScanner event, Emitter<ScanState> emit) async {
    emit(Loading());
    await MediaScanner.instance.scan(
      MediaScanParams(
        MediaType.audio,
        [".mp3", ".wav"],
        "scanned_media.db",
        ExampleDatabase.instance.schemaVersion,
        true,
      ),
    );
  }

  FutureOr<void> _onCreateDB(CreateDB event, Emitter<ScanState> emit) async {
    emit(Loading());
    await Permission.storage.request();
    await event.exampleDatabase.createMigrator().createAll();
    add(StartScanner());
  }

  FutureOr<void> _allMediaScanned(
      AllMediaScanned event, Emitter<ScanState> emit) async {
    emit(Scanned(medias: event.listMedias));
  }
}
