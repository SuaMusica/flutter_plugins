import 'package:drift/drift.dart';

class OfflineMediaV2 extends Table {
  IntColumn get id => integer()();
  IntColumn get albumId =>
      integer().customConstraint('REFERENCES offline_album (id)')();
  IntColumn get playlistId =>
      integer().customConstraint('REFERENCES offline_playlist (id)')();
  TextColumn get downloadId => text().nullable()();
  IntColumn get downloadStatus => integer().nullable()();
  IntColumn get downloadProgress => integer().nullable()();
  IntColumn get isExternal => integer().nullable()();
  TextColumn get name => text().nullable()();
  IntColumn get indexInAlbum => integer().nullable()();
  IntColumn get indexInPlaylist => integer().nullable()();
  TextColumn get shareUrl => text().nullable()();
  TextColumn get path => text().nullable()();
  TextColumn get streamPath => text().nullable()();
  TextColumn get localPath => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get isSd => integer().withDefault(const Constant(0))();
  IntColumn get stillPresent => integer().withDefault(const Constant(1))();
  IntColumn get trackPosition => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id, playlistId, albumId};
}
