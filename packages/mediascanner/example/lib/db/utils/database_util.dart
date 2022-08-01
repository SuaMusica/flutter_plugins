import 'dart:io';

import 'package:mediascanner_example/db/utils/schema_version.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseUtil {
  DatabaseUtil._();

  static final instance = DatabaseUtil._();

  Future<String> getDBPath() async {
    if (Platform.isAndroid) {
      final dbPath = await getDatabasesPath();
      return path.join(dbPath, databaseName);
    }
    final appDocDir = await getApplicationSupportDirectory();
    return path.join(appDocDir.path, databaseName.replaceAll('.db', '_ios.db'));
  }
}
