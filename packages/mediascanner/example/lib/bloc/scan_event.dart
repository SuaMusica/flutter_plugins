part of 'scan_bloc.dart';

abstract class ScanEvent {}

class StartScanner extends ScanEvent {}

class AllMediaScanned extends ScanEvent {
  AllMediaScanned({
    required this.listMedias,
  });
  final List<ScannedMedia> listMedias;
}

class CreateDB extends ScanEvent {
  CreateDB({
    required this.exampleDatabase,
  });

  final ExampleDatabase exampleDatabase;
}
