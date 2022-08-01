class DomainScannedMedia {
  DomainScannedMedia({
    required this.mediaId,
    required this.title,
    required this.artist,
    required this.albumId,
    required this.album,
    required this.track,
    required this.path,
    required this.albumCoverPath,
    required this.playlistId,
    required this.createdAt,
    required this.updatedAt,
    this.totalMusics = 0,
  });

  int? mediaId;
  String? title;
  String? artist;
  int? albumId;
  String? album;
  String? track;
  String? path;
  String? albumCoverPath;
  int playlistId;
  DateTime createdAt;
  DateTime updatedAt;
  int? totalMusics;

  @override
  String toString() {
    return 'DomainScannedMedia{'
        'mediaId: $mediaId, '
        'title: $title, '
        'artist: $artist, '
        'albumId: $albumId, '
        'album: $album, '
        'track: $track, '
        'path: $path, '
        'albumCoverPath: $albumCoverPath, '
        'playlistId: $playlistId, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'totalMusics: $totalMusics'
        '}';
  }
}
