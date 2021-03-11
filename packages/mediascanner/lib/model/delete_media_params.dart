import 'package:mediascanner/model/media_type.dart';

const MEDIA_ID = "id";
const FULL_PATH = "full_path";

class DeleteMediaParams {
  DeleteMediaParams(this.mediaType, this.id, this.fullPath);

  MediaType mediaType;
  int? id;
  String? fullPath;

  Map<String, dynamic> toChannelParams() {
    return {
      MEDIA_TYPE: mediaType.value,
      MEDIA_ID: id,
      FULL_PATH: fullPath,
    };
  }
}
