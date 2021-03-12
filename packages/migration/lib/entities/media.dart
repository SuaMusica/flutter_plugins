import '_map.dart';

class Media {
  Media({
    this.id,
    this.name,
    required this.albumId,
    this.downloadId,
    required this.isExternal,
    this.indexInAlbum,
    this.path,
    this.streamPath,
    this.shareUrl,
    required this.localPath,
    this.createdAt,
    this.downloadProgress,
    this.downloadStatus,
    this.indexInPlaylist,
    required this.playlistId,
  }) : super();

  final int? id;
  final String? name;
  final int albumId;
  final String? downloadId;
  final bool isExternal;
  final int? indexInAlbum;
  final int? indexInPlaylist;
  final int playlistId;
  final int? downloadProgress;
  final String? path;
  final String? streamPath;
  final String localPath;
  final String? shareUrl;
  final int? downloadStatus;
  final DateTime? createdAt;

  factory Media.fromJson(Map<dynamic, dynamic> json) => Media(
        id: json.parseToInt('id'),
        name: json['name'] ?? "",
        albumId: json.parseToInt('album_id'),
        playlistId: json.parseToInt('playlist_id'),
        downloadId: json['download_id'] ?? "",
        isExternal: json['is_external'] ?? false,
        indexInAlbum: json.parseToInt('index_in_album'),
        indexInPlaylist: json.parseToInt('index_in_playlist'),
        path: json['path'] ?? null,
        streamPath: json['stream_path'] ?? "",
        shareUrl: json['share_url'] ?? "",
        localPath: json['local_path'] ?? "",
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
        'playlist_id': this.playlistId,
        'download_id': '0',
        'is_external': this.isExternal,
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
