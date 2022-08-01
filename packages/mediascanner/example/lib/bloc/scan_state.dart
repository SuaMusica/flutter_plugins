part of 'scan_bloc.dart';

abstract class ScanState {}

class ScanInitial extends ScanState {}

class DbCreated extends ScanState {}

class Scanned extends ScanState {
  Scanned({
    required this.medias,
  });

  final List<ScannedMedia> medias;
}

class Loading extends ScanState {}
