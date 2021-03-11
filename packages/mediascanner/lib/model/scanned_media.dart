class ScannedMedia {
  const ScannedMedia(
    this.mediaId,
    this.title,
    this.artist,
    this.albumId,
    this.album,
    this.track,
    this.path,
    this.albumCoverPath,
    this.playlistId,
    this.createdAt,
    this.updatedAt,
  );

  final int mediaId;
  final String title;
  final String artist;
  final int albumId;
  final String album;
  final String? track;
  final String path;
  final int playlistId;
  final String? albumCoverPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ScannedMedia{'
        'mediaId: $mediaId, '
        'title: $title, '
        'artist: $artist, '
        'albumId: $albumId, '
        'album: $album, '
        'track: $track, '
        'playlistId: $playlistId, '
        'path: $path, '
        'albumCoverPath: $albumCoverPath, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
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
      map["album_cover_path"] as String,
      map["playlist"] as int,
      DateTime.fromMillisecondsSinceEpoch(map["created_at"] as int),
      DateTime.fromMillisecondsSinceEpoch(map["updated_at"] as int),
    );
  }

  static List<ScannedMedia> fromList(List<dynamic> mapList) {
    return mapList.where((item) => item is Map<dynamic, dynamic>).map((item) {
      return fromMap(item as Map<dynamic, dynamic>);
    }).toList();
  }
}
