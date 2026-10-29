import 'package:drift/drift.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

import '../database.dart';

class OutboxItem {
  const OutboxItem({required this.id, required this.scanId, required this.attempts, this.lastError});
  final String id;
  final String scanId;
  final int attempts;
  final String? lastError;
}

/// Durable phone-side queue of scans awaiting a host acknowledgement.
class OutboxRepository {
  OutboxRepository(this.db, {this.backoff = const Backoff(), this.maxAttempts = 50});
  final ScanBridgeDatabase db;
  final Backoff backoff;
  final int maxAttempts;

  Future<List<OutboxItem>> due(DateTime now, {int limit = 50}) async {
    final rows = await (db.select(db.deliveryOutbox)
          ..where((o) => o.state.equals('pending') & (o.nextAttemptAt.isNull() | o.nextAttemptAt.isSmallerOrEqualValue(now)))
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)])
          ..limit(limit))
        .get();
    return [for (final r in rows) OutboxItem(id: r.id, scanId: r.aggregateId, attempts: r.attempts, lastError: r.lastError)];
  }

  /// Records a failed attempt; moves to the dead-letter state after [maxAttempts].
  Future<void> recordFailure(OutboxItem item, String error) async {
    final attempts = item.attempts + 1;
    final dead = attempts >= maxAttempts;
    await (db.update(db.deliveryOutbox)..where((o) => o.id.equals(item.id))).write(DeliveryOutboxCompanion(
      attempts: Value(attempts),
      lastError: Value(error),
      nextAttemptAt: Value(nowUtc().add(backoff.delayFor(attempts))),
      state: Value(dead ? 'dead' : 'pending'),
    ));
    if (dead) {
      await (db.update(db.scans)..where((s) => s.id.equals(item.scanId)))
          .write(const ScansCompanion(deliveryStatus: Value('failed')));
    }
  }

  /// Marks the scan's outbox entry done after ack/reject.
  Future<void> complete(String scanId) => (db.update(db.deliveryOutbox)..where((o) => o.aggregateId.equals(scanId)))
      .write(const DeliveryOutboxCompanion(state: Value('done')));

  /// User-triggered retry: re-queues failed/dead entries immediately (same scan ids).
  Future<int> retryAll() => db.transaction(() async {
    final n = await (db.update(db.deliveryOutbox)..where((o) => o.state.isIn(['pending', 'dead'])))
        .write(const DeliveryOutboxCompanion(state: Value('pending'), nextAttemptAt: Value(null)));
    await (db.update(db.scans)..where((s) => s.deliveryStatus.equals('failed')))
        .write(const ScansCompanion(deliveryStatus: Value('queued')));
    return n;
  });

  /// Queues an existing scan again (e.g. a previously local-only scan).
  Future<void> enqueue(String scanId) => db.transaction(() async {
    await (db.delete(db.deliveryOutbox)..where((o) => o.aggregateId.equals(scanId))).go();
    await db.into(db.deliveryOutbox).insert(DeliveryOutboxCompanion.insert(
      id: newId(),
      aggregateId: scanId,
      messageType: 'scan.submit',
      payload: '',
      createdAt: nowUtc(),
      state: 'pending',
    ));
    await (db.update(db.scans)..where((s) => s.id.equals(scanId))).write(const ScansCompanion(deliveryStatus: Value('queued')));
  });

  Stream<int> watchPending() {
    final count = db.deliveryOutbox.id.count();
    final q = db.selectOnly(db.deliveryOutbox)
      ..addColumns([count])
      ..where(db.deliveryOutbox.state.isIn(['pending', 'dead']));
    return q.map((r) => r.read(count) ?? 0).watchSingle();
  }
}
