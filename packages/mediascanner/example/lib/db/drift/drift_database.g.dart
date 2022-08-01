// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: type=lint
class ScannedMediaData extends DataClass
    implements Insertable<ScannedMediaData> {
  final int mediaId;
  final String title;
  final String artist;
  final int albumId;
  final String album;
  final String track;
  final String path;
  final String albumCoverPath;
  final int stillPresent;
  final int createdAt;
  final int updatedAt;
  ScannedMediaData(
      {required this.mediaId,
      required this.title,
      required this.artist,
      required this.albumId,
      required this.album,
      required this.track,
      required this.path,
      required this.albumCoverPath,
      required this.stillPresent,
      required this.createdAt,
      required this.updatedAt});
  factory ScannedMediaData.fromData(Map<String, dynamic> data,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return ScannedMediaData(
      mediaId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}media_id'])!,
      title: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}title'])!,
      artist: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}artist'])!,
      albumId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}album_id'])!,
      album: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}album'])!,
      track: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}track'])!,
      path: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}path'])!,
      albumCoverPath: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}album_cover_path'])!,
      stillPresent: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}still_present'])!,
      createdAt: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at'])!,
      updatedAt: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}updated_at'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<int>(mediaId);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['album_id'] = Variable<int>(albumId);
    map['album'] = Variable<String>(album);
    map['track'] = Variable<String>(track);
    map['path'] = Variable<String>(path);
    map['album_cover_path'] = Variable<String>(albumCoverPath);
    map['still_present'] = Variable<int>(stillPresent);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ScannedMediaCompanion toCompanion(bool nullToAbsent) {
    return ScannedMediaCompanion(
      mediaId: Value(mediaId),
      title: Value(title),
      artist: Value(artist),
      albumId: Value(albumId),
      album: Value(album),
      track: Value(track),
      path: Value(path),
      albumCoverPath: Value(albumCoverPath),
      stillPresent: Value(stillPresent),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScannedMediaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScannedMediaData(
      mediaId: serializer.fromJson<int>(json['mediaId']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      albumId: serializer.fromJson<int>(json['albumId']),
      album: serializer.fromJson<String>(json['album']),
      track: serializer.fromJson<String>(json['track']),
      path: serializer.fromJson<String>(json['path']),
      albumCoverPath: serializer.fromJson<String>(json['albumCoverPath']),
      stillPresent: serializer.fromJson<int>(json['stillPresent']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<int>(mediaId),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'albumId': serializer.toJson<int>(albumId),
      'album': serializer.toJson<String>(album),
      'track': serializer.toJson<String>(track),
      'path': serializer.toJson<String>(path),
      'albumCoverPath': serializer.toJson<String>(albumCoverPath),
      'stillPresent': serializer.toJson<int>(stillPresent),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ScannedMediaData copyWith(
          {int? mediaId,
          String? title,
          String? artist,
          int? albumId,
          String? album,
          String? track,
          String? path,
          String? albumCoverPath,
          int? stillPresent,
          int? createdAt,
          int? updatedAt}) =>
      ScannedMediaData(
        mediaId: mediaId ?? this.mediaId,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        albumId: albumId ?? this.albumId,
        album: album ?? this.album,
        track: track ?? this.track,
        path: path ?? this.path,
        albumCoverPath: albumCoverPath ?? this.albumCoverPath,
        stillPresent: stillPresent ?? this.stillPresent,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('ScannedMediaData(')
          ..write('mediaId: $mediaId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumId: $albumId, ')
          ..write('album: $album, ')
          ..write('track: $track, ')
          ..write('path: $path, ')
          ..write('albumCoverPath: $albumCoverPath, ')
          ..write('stillPresent: $stillPresent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, title, artist, albumId, album, track,
      path, albumCoverPath, stillPresent, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScannedMediaData &&
          other.mediaId == this.mediaId &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.albumId == this.albumId &&
          other.album == this.album &&
          other.track == this.track &&
          other.path == this.path &&
          other.albumCoverPath == this.albumCoverPath &&
          other.stillPresent == this.stillPresent &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScannedMediaCompanion extends UpdateCompanion<ScannedMediaData> {
  final Value<int> mediaId;
  final Value<String> title;
  final Value<String> artist;
  final Value<int> albumId;
  final Value<String> album;
  final Value<String> track;
  final Value<String> path;
  final Value<String> albumCoverPath;
  final Value<int> stillPresent;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ScannedMediaCompanion({
    this.mediaId = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.albumId = const Value.absent(),
    this.album = const Value.absent(),
    this.track = const Value.absent(),
    this.path = const Value.absent(),
    this.albumCoverPath = const Value.absent(),
    this.stillPresent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ScannedMediaCompanion.insert({
    this.mediaId = const Value.absent(),
    required String title,
    required String artist,
    required int albumId,
    required String album,
    required String track,
    required String path,
    required String albumCoverPath,
    this.stillPresent = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  })  : title = Value(title),
        artist = Value(artist),
        albumId = Value(albumId),
        album = Value(album),
        track = Value(track),
        path = Value(path),
        albumCoverPath = Value(albumCoverPath),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ScannedMediaData> custom({
    Expression<int>? mediaId,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<int>? albumId,
    Expression<String>? album,
    Expression<String>? track,
    Expression<String>? path,
    Expression<String>? albumCoverPath,
    Expression<int>? stillPresent,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (albumId != null) 'album_id': albumId,
      if (album != null) 'album': album,
      if (track != null) 'track': track,
      if (path != null) 'path': path,
      if (albumCoverPath != null) 'album_cover_path': albumCoverPath,
      if (stillPresent != null) 'still_present': stillPresent,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ScannedMediaCompanion copyWith(
      {Value<int>? mediaId,
      Value<String>? title,
      Value<String>? artist,
      Value<int>? albumId,
      Value<String>? album,
      Value<String>? track,
      Value<String>? path,
      Value<String>? albumCoverPath,
      Value<int>? stillPresent,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return ScannedMediaCompanion(
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumId: albumId ?? this.albumId,
      album: album ?? this.album,
      track: track ?? this.track,
      path: path ?? this.path,
      albumCoverPath: albumCoverPath ?? this.albumCoverPath,
      stillPresent: stillPresent ?? this.stillPresent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (track.present) {
      map['track'] = Variable<String>(track.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (albumCoverPath.present) {
      map['album_cover_path'] = Variable<String>(albumCoverPath.value);
    }
    if (stillPresent.present) {
      map['still_present'] = Variable<int>(stillPresent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScannedMediaCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('albumId: $albumId, ')
          ..write('album: $album, ')
          ..write('track: $track, ')
          ..write('path: $path, ')
          ..write('albumCoverPath: $albumCoverPath, ')
          ..write('stillPresent: $stillPresent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ScannedMediaTable extends ScannedMedia
    with TableInfo<$ScannedMediaTable, ScannedMediaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScannedMediaTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _mediaIdMeta = const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<int?> mediaId = GeneratedColumn<int?>(
      'media_id', aliasedName, false,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String?> title = GeneratedColumn<String?>(
      'title', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String?> artist = GeneratedColumn<String?>(
      'artist', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _albumIdMeta = const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<int?> albumId = GeneratedColumn<int?>(
      'album_id', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String?> album = GeneratedColumn<String?>(
      'album', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _trackMeta = const VerificationMeta('track');
  @override
  late final GeneratedColumn<String?> track = GeneratedColumn<String?>(
      'track', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String?> path = GeneratedColumn<String?>(
      'path', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _albumCoverPathMeta =
      const VerificationMeta('albumCoverPath');
  @override
  late final GeneratedColumn<String?> albumCoverPath = GeneratedColumn<String?>(
      'album_cover_path', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _stillPresentMeta =
      const VerificationMeta('stillPresent');
  @override
  late final GeneratedColumn<int?> stillPresent = GeneratedColumn<int?>(
      'still_present', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int?> createdAt = GeneratedColumn<int?>(
      'created_at', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int?> updatedAt = GeneratedColumn<int?>(
      'updated_at', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        mediaId,
        title,
        artist,
        albumId,
        album,
        track,
        path,
        albumCoverPath,
        stillPresent,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? 'scanned_media';
  @override
  String get actualTableName => 'scanned_media';
  @override
  VerificationContext validateIntegrity(Insertable<ScannedMediaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    } else if (isInserting) {
      context.missing(_albumMeta);
    }
    if (data.containsKey('track')) {
      context.handle(
          _trackMeta, track.isAcceptableOrUnknown(data['track']!, _trackMeta));
    } else if (isInserting) {
      context.missing(_trackMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('album_cover_path')) {
      context.handle(
          _albumCoverPathMeta,
          albumCoverPath.isAcceptableOrUnknown(
              data['album_cover_path']!, _albumCoverPathMeta));
    } else if (isInserting) {
      context.missing(_albumCoverPathMeta);
    }
    if (data.containsKey('still_present')) {
      context.handle(
          _stillPresentMeta,
          stillPresent.isAcceptableOrUnknown(
              data['still_present']!, _stillPresentMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  ScannedMediaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return ScannedMediaData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $ScannedMediaTable createAlias(String alias) {
    return $ScannedMediaTable(attachedDatabase, alias);
  }
}

class OfflineMediaV2Data extends DataClass
    implements Insertable<OfflineMediaV2Data> {
  final int id;
  final int albumId;
  final int playlistId;
  final String? downloadId;
  final int? downloadStatus;
  final int? downloadProgress;
  final int? isExternal;
  final String? name;
  final int? indexInAlbum;
  final int? indexInPlaylist;
  final String? shareUrl;
  final String? path;
  final String? streamPath;
  final String? localPath;
  final int createdAt;
  final int isSd;
  final int stillPresent;
  final int trackPosition;
  OfflineMediaV2Data(
      {required this.id,
      required this.albumId,
      required this.playlistId,
      this.downloadId,
      this.downloadStatus,
      this.downloadProgress,
      this.isExternal,
      this.name,
      this.indexInAlbum,
      this.indexInPlaylist,
      this.shareUrl,
      this.path,
      this.streamPath,
      this.localPath,
      required this.createdAt,
      required this.isSd,
      required this.stillPresent,
      required this.trackPosition});
  factory OfflineMediaV2Data.fromData(Map<String, dynamic> data,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return OfflineMediaV2Data(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      albumId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}album_id'])!,
      playlistId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}playlist_id'])!,
      downloadId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}download_id']),
      downloadStatus: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}download_status']),
      downloadProgress: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}download_progress']),
      isExternal: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}is_external']),
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name']),
      indexInAlbum: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}index_in_album']),
      indexInPlaylist: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}index_in_playlist']),
      shareUrl: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}share_url']),
      path: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}path']),
      streamPath: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}stream_path']),
      localPath: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}local_path']),
      createdAt: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at'])!,
      isSd: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}is_sd'])!,
      stillPresent: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}still_present'])!,
      trackPosition: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}track_position'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['album_id'] = Variable<int>(albumId);
    map['playlist_id'] = Variable<int>(playlistId);
    if (!nullToAbsent || downloadId != null) {
      map['download_id'] = Variable<String?>(downloadId);
    }
    if (!nullToAbsent || downloadStatus != null) {
      map['download_status'] = Variable<int?>(downloadStatus);
    }
    if (!nullToAbsent || downloadProgress != null) {
      map['download_progress'] = Variable<int?>(downloadProgress);
    }
    if (!nullToAbsent || isExternal != null) {
      map['is_external'] = Variable<int?>(isExternal);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String?>(name);
    }
    if (!nullToAbsent || indexInAlbum != null) {
      map['index_in_album'] = Variable<int?>(indexInAlbum);
    }
    if (!nullToAbsent || indexInPlaylist != null) {
      map['index_in_playlist'] = Variable<int?>(indexInPlaylist);
    }
    if (!nullToAbsent || shareUrl != null) {
      map['share_url'] = Variable<String?>(shareUrl);
    }
    if (!nullToAbsent || path != null) {
      map['path'] = Variable<String?>(path);
    }
    if (!nullToAbsent || streamPath != null) {
      map['stream_path'] = Variable<String?>(streamPath);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String?>(localPath);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['is_sd'] = Variable<int>(isSd);
    map['still_present'] = Variable<int>(stillPresent);
    map['track_position'] = Variable<int>(trackPosition);
    return map;
  }

  OfflineMediaV2Companion toCompanion(bool nullToAbsent) {
    return OfflineMediaV2Companion(
      id: Value(id),
      albumId: Value(albumId),
      playlistId: Value(playlistId),
      downloadId: downloadId == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadId),
      downloadStatus: downloadStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadStatus),
      downloadProgress: downloadProgress == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadProgress),
      isExternal: isExternal == null && nullToAbsent
          ? const Value.absent()
          : Value(isExternal),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      indexInAlbum: indexInAlbum == null && nullToAbsent
          ? const Value.absent()
          : Value(indexInAlbum),
      indexInPlaylist: indexInPlaylist == null && nullToAbsent
          ? const Value.absent()
          : Value(indexInPlaylist),
      shareUrl: shareUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(shareUrl),
      path: path == null && nullToAbsent ? const Value.absent() : Value(path),
      streamPath: streamPath == null && nullToAbsent
          ? const Value.absent()
          : Value(streamPath),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      createdAt: Value(createdAt),
      isSd: Value(isSd),
      stillPresent: Value(stillPresent),
      trackPosition: Value(trackPosition),
    );
  }

  factory OfflineMediaV2Data.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineMediaV2Data(
      id: serializer.fromJson<int>(json['id']),
      albumId: serializer.fromJson<int>(json['albumId']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      downloadId: serializer.fromJson<String?>(json['downloadId']),
      downloadStatus: serializer.fromJson<int?>(json['downloadStatus']),
      downloadProgress: serializer.fromJson<int?>(json['downloadProgress']),
      isExternal: serializer.fromJson<int?>(json['isExternal']),
      name: serializer.fromJson<String?>(json['name']),
      indexInAlbum: serializer.fromJson<int?>(json['indexInAlbum']),
      indexInPlaylist: serializer.fromJson<int?>(json['indexInPlaylist']),
      shareUrl: serializer.fromJson<String?>(json['shareUrl']),
      path: serializer.fromJson<String?>(json['path']),
      streamPath: serializer.fromJson<String?>(json['streamPath']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      isSd: serializer.fromJson<int>(json['isSd']),
      stillPresent: serializer.fromJson<int>(json['stillPresent']),
      trackPosition: serializer.fromJson<int>(json['trackPosition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'albumId': serializer.toJson<int>(albumId),
      'playlistId': serializer.toJson<int>(playlistId),
      'downloadId': serializer.toJson<String?>(downloadId),
      'downloadStatus': serializer.toJson<int?>(downloadStatus),
      'downloadProgress': serializer.toJson<int?>(downloadProgress),
      'isExternal': serializer.toJson<int?>(isExternal),
      'name': serializer.toJson<String?>(name),
      'indexInAlbum': serializer.toJson<int?>(indexInAlbum),
      'indexInPlaylist': serializer.toJson<int?>(indexInPlaylist),
      'shareUrl': serializer.toJson<String?>(shareUrl),
      'path': serializer.toJson<String?>(path),
      'streamPath': serializer.toJson<String?>(streamPath),
      'localPath': serializer.toJson<String?>(localPath),
      'createdAt': serializer.toJson<int>(createdAt),
      'isSd': serializer.toJson<int>(isSd),
      'stillPresent': serializer.toJson<int>(stillPresent),
      'trackPosition': serializer.toJson<int>(trackPosition),
    };
  }

  OfflineMediaV2Data copyWith(
          {int? id,
          int? albumId,
          int? playlistId,
          String? downloadId,
          int? downloadStatus,
          int? downloadProgress,
          int? isExternal,
          String? name,
          int? indexInAlbum,
          int? indexInPlaylist,
          String? shareUrl,
          String? path,
          String? streamPath,
          String? localPath,
          int? createdAt,
          int? isSd,
          int? stillPresent,
          int? trackPosition}) =>
      OfflineMediaV2Data(
        id: id ?? this.id,
        albumId: albumId ?? this.albumId,
        playlistId: playlistId ?? this.playlistId,
        downloadId: downloadId ?? this.downloadId,
        downloadStatus: downloadStatus ?? this.downloadStatus,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        isExternal: isExternal ?? this.isExternal,
        name: name ?? this.name,
        indexInAlbum: indexInAlbum ?? this.indexInAlbum,
        indexInPlaylist: indexInPlaylist ?? this.indexInPlaylist,
        shareUrl: shareUrl ?? this.shareUrl,
        path: path ?? this.path,
        streamPath: streamPath ?? this.streamPath,
        localPath: localPath ?? this.localPath,
        createdAt: createdAt ?? this.createdAt,
        isSd: isSd ?? this.isSd,
        stillPresent: stillPresent ?? this.stillPresent,
        trackPosition: trackPosition ?? this.trackPosition,
      );
  @override
  String toString() {
    return (StringBuffer('OfflineMediaV2Data(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('playlistId: $playlistId, ')
          ..write('downloadId: $downloadId, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('downloadProgress: $downloadProgress, ')
          ..write('isExternal: $isExternal, ')
          ..write('name: $name, ')
          ..write('indexInAlbum: $indexInAlbum, ')
          ..write('indexInPlaylist: $indexInPlaylist, ')
          ..write('shareUrl: $shareUrl, ')
          ..write('path: $path, ')
          ..write('streamPath: $streamPath, ')
          ..write('localPath: $localPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSd: $isSd, ')
          ..write('stillPresent: $stillPresent, ')
          ..write('trackPosition: $trackPosition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      albumId,
      playlistId,
      downloadId,
      downloadStatus,
      downloadProgress,
      isExternal,
      name,
      indexInAlbum,
      indexInPlaylist,
      shareUrl,
      path,
      streamPath,
      localPath,
      createdAt,
      isSd,
      stillPresent,
      trackPosition);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineMediaV2Data &&
          other.id == this.id &&
          other.albumId == this.albumId &&
          other.playlistId == this.playlistId &&
          other.downloadId == this.downloadId &&
          other.downloadStatus == this.downloadStatus &&
          other.downloadProgress == this.downloadProgress &&
          other.isExternal == this.isExternal &&
          other.name == this.name &&
          other.indexInAlbum == this.indexInAlbum &&
          other.indexInPlaylist == this.indexInPlaylist &&
          other.shareUrl == this.shareUrl &&
          other.path == this.path &&
          other.streamPath == this.streamPath &&
          other.localPath == this.localPath &&
          other.createdAt == this.createdAt &&
          other.isSd == this.isSd &&
          other.stillPresent == this.stillPresent &&
          other.trackPosition == this.trackPosition);
}

class OfflineMediaV2Companion extends UpdateCompanion<OfflineMediaV2Data> {
  final Value<int> id;
  final Value<int> albumId;
  final Value<int> playlistId;
  final Value<String?> downloadId;
  final Value<int?> downloadStatus;
  final Value<int?> downloadProgress;
  final Value<int?> isExternal;
  final Value<String?> name;
  final Value<int?> indexInAlbum;
  final Value<int?> indexInPlaylist;
  final Value<String?> shareUrl;
  final Value<String?> path;
  final Value<String?> streamPath;
  final Value<String?> localPath;
  final Value<int> createdAt;
  final Value<int> isSd;
  final Value<int> stillPresent;
  final Value<int> trackPosition;
  const OfflineMediaV2Companion({
    this.id = const Value.absent(),
    this.albumId = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.downloadId = const Value.absent(),
    this.downloadStatus = const Value.absent(),
    this.downloadProgress = const Value.absent(),
    this.isExternal = const Value.absent(),
    this.name = const Value.absent(),
    this.indexInAlbum = const Value.absent(),
    this.indexInPlaylist = const Value.absent(),
    this.shareUrl = const Value.absent(),
    this.path = const Value.absent(),
    this.streamPath = const Value.absent(),
    this.localPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSd = const Value.absent(),
    this.stillPresent = const Value.absent(),
    this.trackPosition = const Value.absent(),
  });
  OfflineMediaV2Companion.insert({
    required int id,
    required int albumId,
    required int playlistId,
    this.downloadId = const Value.absent(),
    this.downloadStatus = const Value.absent(),
    this.downloadProgress = const Value.absent(),
    this.isExternal = const Value.absent(),
    this.name = const Value.absent(),
    this.indexInAlbum = const Value.absent(),
    this.indexInPlaylist = const Value.absent(),
    this.shareUrl = const Value.absent(),
    this.path = const Value.absent(),
    this.streamPath = const Value.absent(),
    this.localPath = const Value.absent(),
    required int createdAt,
    this.isSd = const Value.absent(),
    this.stillPresent = const Value.absent(),
    this.trackPosition = const Value.absent(),
  })  : id = Value(id),
        albumId = Value(albumId),
        playlistId = Value(playlistId),
        createdAt = Value(createdAt);
  static Insertable<OfflineMediaV2Data> custom({
    Expression<int>? id,
    Expression<int>? albumId,
    Expression<int>? playlistId,
    Expression<String?>? downloadId,
    Expression<int?>? downloadStatus,
    Expression<int?>? downloadProgress,
    Expression<int?>? isExternal,
    Expression<String?>? name,
    Expression<int?>? indexInAlbum,
    Expression<int?>? indexInPlaylist,
    Expression<String?>? shareUrl,
    Expression<String?>? path,
    Expression<String?>? streamPath,
    Expression<String?>? localPath,
    Expression<int>? createdAt,
    Expression<int>? isSd,
    Expression<int>? stillPresent,
    Expression<int>? trackPosition,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (albumId != null) 'album_id': albumId,
      if (playlistId != null) 'playlist_id': playlistId,
      if (downloadId != null) 'download_id': downloadId,
      if (downloadStatus != null) 'download_status': downloadStatus,
      if (downloadProgress != null) 'download_progress': downloadProgress,
      if (isExternal != null) 'is_external': isExternal,
      if (name != null) 'name': name,
      if (indexInAlbum != null) 'index_in_album': indexInAlbum,
      if (indexInPlaylist != null) 'index_in_playlist': indexInPlaylist,
      if (shareUrl != null) 'share_url': shareUrl,
      if (path != null) 'path': path,
      if (streamPath != null) 'stream_path': streamPath,
      if (localPath != null) 'local_path': localPath,
      if (createdAt != null) 'created_at': createdAt,
      if (isSd != null) 'is_sd': isSd,
      if (stillPresent != null) 'still_present': stillPresent,
      if (trackPosition != null) 'track_position': trackPosition,
    });
  }

  OfflineMediaV2Companion copyWith(
      {Value<int>? id,
      Value<int>? albumId,
      Value<int>? playlistId,
      Value<String?>? downloadId,
      Value<int?>? downloadStatus,
      Value<int?>? downloadProgress,
      Value<int?>? isExternal,
      Value<String?>? name,
      Value<int?>? indexInAlbum,
      Value<int?>? indexInPlaylist,
      Value<String?>? shareUrl,
      Value<String?>? path,
      Value<String?>? streamPath,
      Value<String?>? localPath,
      Value<int>? createdAt,
      Value<int>? isSd,
      Value<int>? stillPresent,
      Value<int>? trackPosition}) {
    return OfflineMediaV2Companion(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      playlistId: playlistId ?? this.playlistId,
      downloadId: downloadId ?? this.downloadId,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isExternal: isExternal ?? this.isExternal,
      name: name ?? this.name,
      indexInAlbum: indexInAlbum ?? this.indexInAlbum,
      indexInPlaylist: indexInPlaylist ?? this.indexInPlaylist,
      shareUrl: shareUrl ?? this.shareUrl,
      path: path ?? this.path,
      streamPath: streamPath ?? this.streamPath,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
      isSd: isSd ?? this.isSd,
      stillPresent: stillPresent ?? this.stillPresent,
      trackPosition: trackPosition ?? this.trackPosition,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (downloadId.present) {
      map['download_id'] = Variable<String?>(downloadId.value);
    }
    if (downloadStatus.present) {
      map['download_status'] = Variable<int?>(downloadStatus.value);
    }
    if (downloadProgress.present) {
      map['download_progress'] = Variable<int?>(downloadProgress.value);
    }
    if (isExternal.present) {
      map['is_external'] = Variable<int?>(isExternal.value);
    }
    if (name.present) {
      map['name'] = Variable<String?>(name.value);
    }
    if (indexInAlbum.present) {
      map['index_in_album'] = Variable<int?>(indexInAlbum.value);
    }
    if (indexInPlaylist.present) {
      map['index_in_playlist'] = Variable<int?>(indexInPlaylist.value);
    }
    if (shareUrl.present) {
      map['share_url'] = Variable<String?>(shareUrl.value);
    }
    if (path.present) {
      map['path'] = Variable<String?>(path.value);
    }
    if (streamPath.present) {
      map['stream_path'] = Variable<String?>(streamPath.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String?>(localPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (isSd.present) {
      map['is_sd'] = Variable<int>(isSd.value);
    }
    if (stillPresent.present) {
      map['still_present'] = Variable<int>(stillPresent.value);
    }
    if (trackPosition.present) {
      map['track_position'] = Variable<int>(trackPosition.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineMediaV2Companion(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('playlistId: $playlistId, ')
          ..write('downloadId: $downloadId, ')
          ..write('downloadStatus: $downloadStatus, ')
          ..write('downloadProgress: $downloadProgress, ')
          ..write('isExternal: $isExternal, ')
          ..write('name: $name, ')
          ..write('indexInAlbum: $indexInAlbum, ')
          ..write('indexInPlaylist: $indexInPlaylist, ')
          ..write('shareUrl: $shareUrl, ')
          ..write('path: $path, ')
          ..write('streamPath: $streamPath, ')
          ..write('localPath: $localPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSd: $isSd, ')
          ..write('stillPresent: $stillPresent, ')
          ..write('trackPosition: $trackPosition')
          ..write(')'))
        .toString();
  }
}

class $OfflineMediaV2Table extends OfflineMediaV2
    with TableInfo<$OfflineMediaV2Table, OfflineMediaV2Data> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineMediaV2Table(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _albumIdMeta = const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<int?> albumId = GeneratedColumn<int?>(
      'album_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES offline_album (id)');
  final VerificationMeta _playlistIdMeta = const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<int?> playlistId = GeneratedColumn<int?>(
      'playlist_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES offline_playlist (id)');
  final VerificationMeta _downloadIdMeta = const VerificationMeta('downloadId');
  @override
  late final GeneratedColumn<String?> downloadId = GeneratedColumn<String?>(
      'download_id', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _downloadStatusMeta =
      const VerificationMeta('downloadStatus');
  @override
  late final GeneratedColumn<int?> downloadStatus = GeneratedColumn<int?>(
      'download_status', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _downloadProgressMeta =
      const VerificationMeta('downloadProgress');
  @override
  late final GeneratedColumn<int?> downloadProgress = GeneratedColumn<int?>(
      'download_progress', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _isExternalMeta = const VerificationMeta('isExternal');
  @override
  late final GeneratedColumn<int?> isExternal = GeneratedColumn<int?>(
      'is_external', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _indexInAlbumMeta =
      const VerificationMeta('indexInAlbum');
  @override
  late final GeneratedColumn<int?> indexInAlbum = GeneratedColumn<int?>(
      'index_in_album', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _indexInPlaylistMeta =
      const VerificationMeta('indexInPlaylist');
  @override
  late final GeneratedColumn<int?> indexInPlaylist = GeneratedColumn<int?>(
      'index_in_playlist', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _shareUrlMeta = const VerificationMeta('shareUrl');
  @override
  late final GeneratedColumn<String?> shareUrl = GeneratedColumn<String?>(
      'share_url', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String?> path = GeneratedColumn<String?>(
      'path', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _streamPathMeta = const VerificationMeta('streamPath');
  @override
  late final GeneratedColumn<String?> streamPath = GeneratedColumn<String?>(
      'stream_path', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _localPathMeta = const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String?> localPath = GeneratedColumn<String?>(
      'local_path', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int?> createdAt = GeneratedColumn<int?>(
      'created_at', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _isSdMeta = const VerificationMeta('isSd');
  @override
  late final GeneratedColumn<int?> isSd = GeneratedColumn<int?>(
      'is_sd', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  final VerificationMeta _stillPresentMeta =
      const VerificationMeta('stillPresent');
  @override
  late final GeneratedColumn<int?> stillPresent = GeneratedColumn<int?>(
      'still_present', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  final VerificationMeta _trackPositionMeta =
      const VerificationMeta('trackPosition');
  @override
  late final GeneratedColumn<int?> trackPosition = GeneratedColumn<int?>(
      'track_position', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        albumId,
        playlistId,
        downloadId,
        downloadStatus,
        downloadProgress,
        isExternal,
        name,
        indexInAlbum,
        indexInPlaylist,
        shareUrl,
        path,
        streamPath,
        localPath,
        createdAt,
        isSd,
        stillPresent,
        trackPosition
      ];
  @override
  String get aliasedName => _alias ?? 'offline_media_v2';
  @override
  String get actualTableName => 'offline_media_v2';
  @override
  VerificationContext validateIntegrity(Insertable<OfflineMediaV2Data> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('download_id')) {
      context.handle(
          _downloadIdMeta,
          downloadId.isAcceptableOrUnknown(
              data['download_id']!, _downloadIdMeta));
    }
    if (data.containsKey('download_status')) {
      context.handle(
          _downloadStatusMeta,
          downloadStatus.isAcceptableOrUnknown(
              data['download_status']!, _downloadStatusMeta));
    }
    if (data.containsKey('download_progress')) {
      context.handle(
          _downloadProgressMeta,
          downloadProgress.isAcceptableOrUnknown(
              data['download_progress']!, _downloadProgressMeta));
    }
    if (data.containsKey('is_external')) {
      context.handle(
          _isExternalMeta,
          isExternal.isAcceptableOrUnknown(
              data['is_external']!, _isExternalMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('index_in_album')) {
      context.handle(
          _indexInAlbumMeta,
          indexInAlbum.isAcceptableOrUnknown(
              data['index_in_album']!, _indexInAlbumMeta));
    }
    if (data.containsKey('index_in_playlist')) {
      context.handle(
          _indexInPlaylistMeta,
          indexInPlaylist.isAcceptableOrUnknown(
              data['index_in_playlist']!, _indexInPlaylistMeta));
    }
    if (data.containsKey('share_url')) {
      context.handle(_shareUrlMeta,
          shareUrl.isAcceptableOrUnknown(data['share_url']!, _shareUrlMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    }
    if (data.containsKey('stream_path')) {
      context.handle(
          _streamPathMeta,
          streamPath.isAcceptableOrUnknown(
              data['stream_path']!, _streamPathMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_sd')) {
      context.handle(
          _isSdMeta, isSd.isAcceptableOrUnknown(data['is_sd']!, _isSdMeta));
    }
    if (data.containsKey('still_present')) {
      context.handle(
          _stillPresentMeta,
          stillPresent.isAcceptableOrUnknown(
              data['still_present']!, _stillPresentMeta));
    }
    if (data.containsKey('track_position')) {
      context.handle(
          _trackPositionMeta,
          trackPosition.isAcceptableOrUnknown(
              data['track_position']!, _trackPositionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, playlistId, albumId};
  @override
  OfflineMediaV2Data map(Map<String, dynamic> data, {String? tablePrefix}) {
    return OfflineMediaV2Data.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $OfflineMediaV2Table createAlias(String alias) {
    return $OfflineMediaV2Table(attachedDatabase, alias);
  }
}

abstract class _$ExampleDatabase extends GeneratedDatabase {
  _$ExampleDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$ExampleDatabase.connect(DatabaseConnection c) : super.connect(c);
  late final $ScannedMediaTable scannedMedia = $ScannedMediaTable(this);
  late final $OfflineMediaV2Table offlineMediaV2 = $OfflineMediaV2Table(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [scannedMedia, offlineMediaV2];
}
