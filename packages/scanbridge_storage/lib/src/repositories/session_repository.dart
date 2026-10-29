import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

import '../database.dart';
import '../mappers.dart';

enum SessionSort { updatedDesc, createdDesc, createdAsc, name }

class SessionRepository {
  SessionRepository(this.db);
  final ScanBridgeDatabase db;

  Stream<List<ScanSession>> watch({String search = '', bool archived = false, SessionSort sort = SessionSort.updatedDesc}) {
    final count = db.scans.id.count();
    final q = db.select(db.sessions).join([
      leftOuterJoin(db.scans, db.scans.sessionId.equalsExp(db.sessions.id) & db.scans.deletedAt.isNull(), useColumns: false),
    ])
      ..addColumns([count])
      ..where(archived ? db.sessions.archivedAt.isNotNull() : db.sessions.archivedAt.isNull())
      ..groupBy([db.sessions.id]);
    if (search.isNotEmpty) q.where(db.sessions.name.contains(search) | db.sessions.notes.contains(search));
    q.orderBy([
      switch (sort) {
        SessionSort.updatedDesc => OrderingTerm.desc(db.sessions.updatedAt),
        SessionSort.createdDesc => OrderingTerm.desc(db.sessions.createdAt),
        SessionSort.createdAsc => OrderingTerm.asc(db.sessions.createdAt),
        SessionSort.name => OrderingTerm.asc(db.sessions.name),
      },
    ]);
    return q.watch().map((rows) => [
      for (final r in rows) r.readTable(db.sessions).toDomain(scanCount: r.read(count) ?? 0),
    ]);
  }

  Future<ScanSession?> byId(String id) async =>
      (await (db.select(db.sessions)..where((s) => s.id.equals(id))).getSingleOrNull())?.toDomain();

  Future<ScanSession> create(String name, {String? deviceId}) async {
    final now = nowUtc();
    final s = ScanSession(id: newId(), name: name, createdAt: now, updatedAt: now, sourceDeviceId: deviceId);
    await db.into(db.sessions).insert(s.toCompanion());
    return s;
  }

  Future<void> update(String id, {String? name, String? notes, List<String>? tags}) =>
      (db.update(db.sessions)..where((s) => s.id.equals(id))).write(SessionsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        notes: notes == null ? const Value.absent() : Value(notes),
        tags: tags == null ? const Value.absent() : Value(jsonEncode(tags)),
        updatedAt: Value(nowUtc()),
      ));

  /// Remote rename/create from a phone; never overwrites an existing creation time.
  Future<void> upsertName(String id, String name, {String? deviceId}) async {
    final now = nowUtc();
    await db.into(db.sessions).insert(
      SessionsCompanion.insert(id: id, name: name, createdAt: now, updatedAt: now, sourceDeviceId: Value(deviceId)),
      onConflict: DoUpdate((_) => SessionsCompanion(name: Value(name), updatedAt: Value(now))),
    );
  }

  Future<void> setArchived(String id, bool archived) => (db.update(db.sessions)..where((s) => s.id.equals(id)))
      .write(SessionsCompanion(archivedAt: Value(archived ? nowUtc() : null)));

  /// Hard delete with cascade to scans. Callers must confirm with the user first.
  Future<void> delete(String id) => db.transaction(() async {
    await (db.delete(db.scans)..where((s) => s.sessionId.equals(id))).go();
    await (db.delete(db.sessions)..where((s) => s.id.equals(id))).go();
  });

  /// Moves all scans of [sourceIds] into [targetId] and removes the sources.
  Future<void> merge(String targetId, Iterable<String> sourceIds) => db.transaction(() async {
    final sources = sourceIds.where((id) => id != targetId).toList();
    await (db.update(db.scans)..where((s) => s.sessionId.isIn(sources))).write(ScansCompanion(sessionId: Value(targetId)));
    await (db.delete(db.sessions)..where((s) => s.id.isIn(sources))).go();
    await update(targetId);
  });
}
