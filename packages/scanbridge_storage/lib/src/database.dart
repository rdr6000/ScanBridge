import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Devices,
  Sessions,
  Scans,
  DeliveryOutbox,
  Templates,
  TemplateVersions,
  TemplateRuns,
  AppSettings,
  AuditEvents,
])
class ScanBridgeDatabase extends _$ScanBridgeDatabase {
  ScanBridgeDatabase(super.executor);

  /// Opens (or creates) the database file with WAL and foreign keys.
  factory ScanBridgeDatabase.open(File file) => ScanBridgeDatabase(NativeDatabase.createInBackground(
    file,
    setup: (db) {
      db.execute('PRAGMA journal_mode = WAL;');
      db.execute('PRAGMA busy_timeout = 5000;');
    },
  ));

  factory ScanBridgeDatabase.memory() => ScanBridgeDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Add `from1To2` etc. here; each step must be covered by a migration test.
    onUpgrade: (m, from, to) async {},
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  /// Consistent online copy of the database (SQLite `VACUUM INTO`).
  Future<void> backupTo(File target) async {
    if (target.existsSync()) target.deleteSync();
    await customStatement('VACUUM INTO ?', [target.path]);
  }

  Future<int> sizeBytes() async {
    final pages = await customSelect('PRAGMA page_count').getSingle();
    final size = await customSelect('PRAGMA page_size').getSingle();
    return (pages.data.values.first as int) * (size.data.values.first as int);
  }
}
