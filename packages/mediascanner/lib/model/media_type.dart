const MEDIA_TYPE = "media_type";
const DATABASE_NAME = "database_name";
const DATABASE_VERSION = "database_version";

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
