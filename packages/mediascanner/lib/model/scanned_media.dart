class ScannedMedia {
  ScannedMedia(this.mediaId, this.title, this.artist, this.albumId, this.album, this.track,
      this.path, this.albumCoverPath);

  int mediaId;
  String title;
  String artist;
  int albumId;
  String album;
  String track;
  String path;
  String albumCoverPath;

  @override
  String toString() {
    return 'ScannedMedia{'
        'mediaId: $mediaId, '
        'title: $title, '
        'artist: $artist, '
        'albumId: $albumId, '
        'album: $album, '
        'track: $track, '
        'path: $path, '
        'albumCoverPath: $albumCoverPath'
        '}';
  }

  static ScannedMedia fromMap(Map<dynamic, dynamic> map) {
    return ScannedMedia(
        map["mediaId"] as int,
        map["title"] as String,
        map["artist"] as String,
        map["albumId"] as int,
        map["album"] as String,
        map["track"] as String,
        map["path"] as String,
        map["album_cover_path"] as String);
  }

  static List<ScannedMedia> fromList(List<dynamic> mapList) {
    return mapList.where((item) => item is Map<dynamic, dynamic>).map((item) {
      return fromMap(item as Map<dynamic, dynamic>);
    }).toList();
  }
}
