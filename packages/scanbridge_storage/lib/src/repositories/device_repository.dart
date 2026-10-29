import 'package:drift/drift.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

import '../database.dart';
import '../mappers.dart';

/// Paired devices. Secrets live in OS secure storage, never in this table.
class DeviceRepository {
  DeviceRepository(this.db);
  final ScanBridgeDatabase db;

  Stream<List<Device>> watchAll() => (db.select(db.devices)..orderBy([(d) => OrderingTerm.desc(d.lastSeenAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  Future<Device?> byId(String id) async =>
      (await (db.select(db.devices)..where((d) => d.id.equals(id))).getSingleOrNull())?.toDomain();

  Future<void> upsert(Device device) => db.into(db.devices).insertOnConflictUpdate(device.toCompanion());

  Future<void> touch(String id) =>
      (db.update(db.devices)..where((d) => d.id.equals(id))).write(DevicesCompanion(lastSeenAt: Value(nowUtc())));

  Future<void> rename(String id, String name) =>
      (db.update(db.devices)..where((d) => d.id.equals(id))).write(DevicesCompanion(name: Value(name)));

  Future<void> setStatus(String id, DeviceStatus status) =>
      (db.update(db.devices)..where((d) => d.id.equals(id))).write(DevicesCompanion(status: Value(status.name)));

  Future<void> setCanSubmit(String id, bool allowed) =>
      (db.update(db.devices)..where((d) => d.id.equals(id))).write(DevicesCompanion(canSubmitScans: Value(allowed)));

  Future<void> delete(String id) => (db.delete(db.devices)..where((d) => d.id.equals(id))).go();
}

/// Small JSON key/value settings store.
class SettingsRepository {
  SettingsRepository(this.db);
  final ScanBridgeDatabase db;

  Future<String?> get(String key) async =>
      (await (db.select(db.appSettings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Stream<String?> watch(String key) =>
      (db.select(db.appSettings)..where((s) => s.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  Future<void> set(String key, String value) =>
      db.into(db.appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));
}

/// Audit trail; callers must pass already-redacted details.
class AuditRepository {
  AuditRepository(this.db, {this.keep = 5000});
  final ScanBridgeDatabase db;
  final int keep;

  Future<void> log(String category, String action, {String? entityId, String details = ''}) async {
    await db.into(db.auditEvents).insert(AuditEventsCompanion.insert(
      id: newId(),
      timestamp: nowUtc(),
      category: category,
      action: action,
      entityId: Value(entityId),
      details: Value(details),
    ));
  }

  Stream<List<AuditEvent>> watchRecent({int limit = 200}) => (db.select(db.auditEvents)
        ..orderBy([(a) => OrderingTerm.desc(a.timestamp)])
        ..limit(limit))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  /// Keeps only the newest [keep] events.
  Future<void> prune() => db.customStatement(
    'DELETE FROM audit_events WHERE id NOT IN (SELECT id FROM audit_events ORDER BY timestamp DESC LIMIT ?)',
    [keep],
  );
}
