import 'package:drift/drift.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

import '../database.dart';
import '../mappers.dart';

/// Query options for scan lists. All filters are optional.
class ScanFilter {
  const ScanFilter({
    this.sessionId,
    this.text = '',
    this.deliveryStatuses = const {},
    this.outputStatuses = const {},
    this.validation,
    this.symbology,
    this.deviceId,
    this.from,
    this.to,
    this.newestFirst = true,
    this.limit = 500,
    this.includeDeleted = false,
  });

  final String? sessionId;
  final String text;
  final Set<DeliveryStatus> deliveryStatuses;
  final Set<OutputStatus> outputStatuses;
  final ValidationStatus? validation;
  final Symbology? symbology;
  final String? deviceId;
  final DateTime? from;
  final DateTime? to;
  final bool newestFirst;
  final int limit;
  final bool includeDeleted;
}

class ScanRepository {
  ScanRepository(this.db);
  final ScanBridgeDatabase db;

  Future<void> _touchSession(String id, String name, String? deviceId, DateTime now) =>
      db.into(db.sessions).insert(
        SessionsCompanion.insert(id: id, name: name, createdAt: now, updatedAt: now, sourceDeviceId: Value(deviceId)),
        onConflict: DoUpdate((_) => SessionsCompanion(updatedAt: Value(now))),
      );

  /// Phone side: scan + outbox row in one transaction (persist before send).
  Future<void> captureWithOutbox(ScanRecord scan, ScanSession session) => db.transaction(() async {
    final now = nowUtc();
    await _touchSession(session.id, session.name, scan.deviceId, now);
    await db.into(db.scans).insert(scan.toCompanion());
    await db.into(db.deliveryOutbox).insert(DeliveryOutboxCompanion.insert(
      id: newId(),
      aggregateId: scan.id,
      messageType: 'scan.submit',
      payload: '',
      createdAt: now,
      state: 'pending',
    ));
  });

  /// Phone side: local-only scan (no host paired / offline mode by choice).
  Future<void> captureLocal(ScanRecord scan, ScanSession session) => db.transaction(() async {
    await _touchSession(session.id, session.name, scan.deviceId, nowUtc());
    await db.into(db.scans).insert(scan.toCompanion());
  });

  /// Host side: idempotent insert keyed by scan id. Returns (stored, wasAlreadyStored).
  Future<(ScanRecord, bool)> receive(ScanRecord scan, {required String sessionName}) => db.transaction(() async {
    final existing = await byId(scan.id);
    if (existing != null) return (existing, true);
    await _touchSession(scan.sessionId, sessionName, scan.deviceId, scan.receivedAt ?? nowUtc());
    await db.into(db.scans).insert(scan.toCompanion());
    return (scan, false);
  });

  Future<ScanRecord?> byId(String id) async =>
      (await (db.select(db.scans)..where((s) => s.id.equals(id))).getSingleOrNull())?.toDomain();

  SimpleSelectStatement<$ScansTable, ScanRow> _query(ScanFilter f) {
    final q = db.select(db.scans);
    q.where((s) {
      final parts = <Expression<bool>>[
        if (!f.includeDeleted) s.deletedAt.isNull(),
        if (f.sessionId != null) s.sessionId.equals(f.sessionId!),
        if (f.text.isNotEmpty) s.normalizedValue.contains(f.text) | s.rawValue.contains(f.text),
        if (f.deliveryStatuses.isNotEmpty) s.deliveryStatus.isIn(f.deliveryStatuses.map((e) => e.name)),
        if (f.outputStatuses.isNotEmpty) s.outputStatus.isIn(f.outputStatuses.map((e) => e.name)),
        if (f.validation != null) s.validationStatus.equals(f.validation!.name),
        if (f.symbology != null) s.symbology.equals(f.symbology!.name),
        if (f.deviceId != null) s.deviceId.equals(f.deviceId!),
        if (f.from != null) s.capturedAt.isBiggerOrEqualValue(f.from!),
        if (f.to != null) s.capturedAt.isSmallerThanValue(f.to!),
      ];
      return parts.isEmpty ? const Constant(true) : parts.reduce((a, b) => a & b);
    });
    q
      ..orderBy([(s) => OrderingTerm(expression: s.capturedAt, mode: f.newestFirst ? OrderingMode.desc : OrderingMode.asc)])
      ..limit(f.limit);
    return q;
  }

  Stream<List<ScanRecord>> watch(ScanFilter filter) =>
      _query(filter).watch().map((rows) => rows.map((r) => r.toDomain()).toList());

  Future<List<ScanRecord>> list(ScanFilter filter) async => (await _query(filter).get()).map((r) => r.toDomain()).toList();

  Future<List<ScanRecord>> forSession(String sessionId) =>
      list(ScanFilter(sessionId: sessionId, newestFirst: false, limit: 1 << 30));

  Future<bool> valueExistsInSession(String sessionId, String value, {String? exceptId}) async {
    final q = db.select(db.scans)
      ..where((s) => s.sessionId.equals(sessionId) & s.normalizedValue.equals(value) & s.deletedAt.isNull())
      ..limit(2);
    final rows = await q.get();
    return rows.any((r) => r.id != exceptId);
  }

  Future<void> setStatus(String id, {DeliveryStatus? delivery, OutputStatus? output, String? Function()? outputError}) =>
      (db.update(db.scans)..where((s) => s.id.equals(id))).write(ScansCompanion(
        deliveryStatus: delivery == null ? const Value.absent() : Value(delivery.name),
        outputStatus: output == null ? const Value.absent() : Value(output.name),
        outputError: outputError == null ? const Value.absent() : Value(outputError()),
      ));

  /// Operator edit of value/quantity/metadata.
  Future<void> edit(String id, {String? value, String? quantity}) =>
      (db.update(db.scans)..where((s) => s.id.equals(id))).write(ScansCompanion(
        rawValue: value == null ? const Value.absent() : Value(value),
        normalizedValue: value == null ? const Value.absent() : Value(value),
        quantity: quantity == null ? const Value.absent() : Value(quantity),
      ));

  /// Soft delete so the UI can offer undo.
  Future<void> softDelete(Iterable<String> ids) => (db.update(db.scans)..where((s) => s.id.isIn(ids)))
      .write(ScansCompanion(deletedAt: Value(nowUtc())));

  Future<void> undoDelete(Iterable<String> ids) =>
      (db.update(db.scans)..where((s) => s.id.isIn(ids))).write(const ScansCompanion(deletedAt: Value(null)));

  /// Intentional duplicate of an existing scan with a fresh id.
  Future<ScanRecord?> duplicate(String id) async {
    final s = await byId(id);
    if (s == null) return null;
    final copy = ScanRecord(
      id: newId(),
      sessionId: s.sessionId,
      deviceId: s.deviceId,
      rawValue: s.rawValue,
      symbology: s.symbology,
      quantity: s.quantity,
      capturedAt: nowUtc(),
      receivedAt: s.receivedAt,
      source: s.source,
      validationStatus: ValidationStatus.duplicate,
      deliveryStatus: DeliveryStatus.localOnly,
      values: s.values,
    );
    await db.into(db.scans).insert(copy.toCompanion());
    return copy;
  }

  /// Duplicate values in a session grouped by value (for dedupe preview).
  Future<Map<String, List<ScanRecord>>> duplicateGroups(String sessionId) async {
    final groups = <String, List<ScanRecord>>{};
    for (final s in await forSession(sessionId)) {
      groups.putIfAbsent(s.value, () => []).add(s);
    }
    groups.removeWhere((_, v) => v.length < 2);
    return groups;
  }

  /// Host restart recovery: output that was in flight is not assumed done.
  Future<int> markInterruptedOutput() => (db.update(db.scans)..where((s) => s.outputStatus.equals(OutputStatus.pending.name)))
      .write(const ScansCompanion(outputStatus: Value('failed'), outputError: Value('Interrupted by restart; retry manually')));

  Stream<int> watchCount({DeliveryStatus? delivery, OutputStatus? output}) {
    final count = db.scans.id.count();
    final q = db.selectOnly(db.scans)
      ..addColumns([count])
      ..where(db.scans.deletedAt.isNull() &
          (delivery == null ? const Constant(true) : db.scans.deliveryStatus.equals(delivery.name)) &
          (output == null ? const Constant(true) : db.scans.outputStatus.equals(output.name)));
    return q.map((r) => r.read(count) ?? 0).watchSingle();
  }
}
