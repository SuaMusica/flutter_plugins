import '_map.dart';

class Media {
  Media({
    this.id,
    this.name,
    this.albumId,
    this.downloadId,
    this.isExternal,
    this.indexInAlbum,
    this.path,
    this.streamPath,
    this.shareUrl,
    this.localPath,
    this.createdAt,
    this.downloadProgress,
    this.downloadStatus,
    this.indexInPlaylist,
    this.playlistId,
  }) : super();

  final int id;
  final String name;
  final int albumId;
  final String downloadId;
  final bool isExternal;
  final int indexInAlbum;
  final int indexInPlaylist;
  final int playlistId;
  final int downloadProgress;
  final String path;
  final String streamPath;
  final String localPath;
  final String shareUrl;
  final int downloadStatus;
  final DateTime createdAt;

  factory Media.fromJson(Map<dynamic, dynamic> json) => Media(
        id: json.parseToInt('id'),
        name: json['name'] as String,
        albumId: json.parseToInt('album_id'),
        playlistId: json.parseToInt('playlist_id'),
        downloadId: json['download_id'] as String,
        isExternal: json['is_external'] as bool,
        indexInAlbum: json.parseToInt('index_in_album'),
        indexInPlaylist: json.parseToInt('index_in_playlist'),
        path: json['path'] as String,
        streamPath: json['stream_path'] as String,
        shareUrl: json['share_url'] as String,
        localPath: json['local_path'] as String,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                json.parseToInt('created_at')),
        downloadProgress: json.parseToInt('download_progress'),
        downloadStatus: json.parseToInt('download_status'),
      );

  Map<String, dynamic> toJson() => {
        'id': this.id,
        'name': this.name,
        'album_id': this.albumId,
        'playlist_id': this.playlistId ?? -1,
        'download_id': '0',
        'is_external': this.isExternal ?? false,
        'index_in_album': this.indexInAlbum ?? -1,
        'index_in_playlist': this.indexInPlaylist ?? -1,
        'download_progress': this.downloadProgress ?? 100,
        'path': this.path,
        'stream_path': this.streamPath,
        'local_path': this.localPath.replaceAll("/storage/emulated/0/", "/"),
        'share_url': this.shareUrl,
        'download_status': this.downloadStatus ?? 3,
        'created_at': this.createdAt?.toIso8601String(),
      };
}
