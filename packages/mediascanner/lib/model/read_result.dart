import 'package:mediascanner/model/scanned_media.dart';

class ReadResult {
  ReadResult(
    this.scannedMedia,
    this.error,
  );

  ScannedMedia scannedMedia;
  String? error;

  @override
  String toString() {
    return 'ReadResult{'
        'scannedMedia: $scannedMedia,'
        'error: $error'
        '}';
  }

  static ReadResult fromMap(Map<dynamic, dynamic> map) {
    return ReadResult(
      ScannedMedia.fromMap(map["media"] as Map<dynamic, dynamic>),
      map["error"],
    );
  }
}
