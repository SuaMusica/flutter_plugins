import 'package:drift/drift.dart';

class ScannedMedia extends Table {
  IntColumn get mediaId => integer()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  IntColumn get albumId => integer()();
  TextColumn get album => text()();
  TextColumn get track => text()();
  TextColumn get path => text()();
  TextColumn get albumCoverPath => text()();
  IntColumn get stillPresent => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {mediaId};
}
