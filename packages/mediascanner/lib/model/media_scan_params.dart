import 'package:mediascanner/model/media_type.dart';

const SUPPORTED_EXTENSIONS = "supported_extensions";

class MediaScanParams {
  MediaScanParams(this.mediaType, this.supportedExtensions);

  MediaType mediaType;
  List<String> supportedExtensions;

  Map<String, dynamic> toChannelParams() {
    return {
      MEDIA_TYPE: mediaType.value,
      SUPPORTED_EXTENSIONS: supportedExtensions
    };
  }
}