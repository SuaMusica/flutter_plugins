const MEDIA_TYPE = "media_type";
const SUPPORTED_EXTENSIONS = "supported_extensions";

enum MediaType { audio, video, all }

extension ToChannelParam on MediaType {
  String get value {
    switch (this) {
      case MediaType.audio:
        return "AUDIO";
      case MediaType.video:
        return "VIDEO";
      case MediaType.all:
      default:
        return "ALL";
    }
  }
}

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
