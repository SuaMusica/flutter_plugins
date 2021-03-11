import 'package:mediascanner/model/media_type.dart';

const SUPPORTED_EXTENSIONS = "supported_extensions";

class MediaScanParams {
  MediaScanParams(
      this.mediaType,
      this.supportedExtensions,
      this.databaseName,
      this.databaseVersion,
      );

  MediaType mediaType;
  List<String> supportedExtensions;
  String databaseName;
  int databaseVersion;

  Map<String, dynamic> toChannelParams() {
    return {
      MEDIA_TYPE: mediaType.value,
      SUPPORTED_EXTENSIONS: supportedExtensions,
      DATABASE_NAME: databaseName,
      DATABASE_VERSION: databaseVersion,
    };
  }
}
