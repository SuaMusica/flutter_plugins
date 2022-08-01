import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:mediascanner_example/db/drift/tables/offline_media.dart';
import 'package:mediascanner_example/db/drift/tables/scanned_media.dart';
import 'package:mediascanner_example/db/utils/database_util.dart';
import 'package:mediascanner_example/db/utils/schema_version.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'drift_database.g.dart';

@DriftDatabase(
  tables: [
    ScannedMedia,
    OfflineMediaV2,
  ],
)
class ExampleDatabase extends _$ExampleDatabase {
  ExampleDatabase(QueryExecutor e) : super(e);
  ExampleDatabase._() : super(openConnection());
  ExampleDatabase.connect(DatabaseConnection c) : super.connect(c);

  static final ExampleDatabase _singleton = ExampleDatabase._();

  static ExampleDatabase get instance => _singleton;

  @override
  int get schemaVersion => defaultSchemaVersion;

  @override
  MigrationStrategy get migration {
    debugPrint('#DRIFT: migration');
    return MigrationStrategy(
      onCreate: dataMigrationHandler,
    );
  }

  Future<void> dataMigrationHandler(Migrator migrator) async {
    try {
      debugPrint('#DRIFT: Create DB');
      await migrator.drop(scannedMedia);
      await migrator.drop(offlineMediaV2);
      await migrator.createAll();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

LazyDatabase openConnection() {
  applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(
    () async {
      debugPrint('#DRIFT: OPEN');
      final dbPath = await DatabaseUtil.instance.getDBPath();
      final file = File(dbPath);
      file.open();
      debugPrint('#DRIFT: ${file.absolute}');
      return NativeDatabase(
        file,
        logStatements: kDebugMode,
      );
    },
  );
}

class OldUser implements QueryExecutorUser {
  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {
    debugPrint('old Database Before Open');
  }

  @override
  int get schemaVersion => 1;
}
