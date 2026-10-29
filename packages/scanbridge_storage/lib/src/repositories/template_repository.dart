import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

import '../database.dart';

/// Templates with full version history; edits never overwrite old versions.
class TemplateRepository {
  TemplateRepository(this.db);
  final ScanBridgeDatabase db;

  OutputTemplate _decode(String json) => OutputTemplate.fromJson((jsonDecode(json) as Map).cast<String, Object?>());

  Stream<List<OutputTemplate>> watchAll() {
    final q = db.select(db.templates).join([
      innerJoin(
        db.templateVersions,
        db.templateVersions.templateId.equalsExp(db.templates.id) &
            db.templateVersions.version.equalsExp(db.templates.currentVersion),
      ),
    ])
      ..orderBy([OrderingTerm.asc(db.templates.name)]);
    return q.watch().map((rows) => [for (final r in rows) _decode(r.readTable(db.templateVersions).json)]);
  }

  Future<List<OutputTemplate>> all() => watchAll().first;

  /// Current version, or a specific historical [version].
  Future<OutputTemplate?> get(String id, {int? version}) async {
    final row = await (db.select(db.templates)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final v = version ?? row.currentVersion;
    final vr = await (db.select(db.templateVersions)..where((t) => t.templateId.equals(id) & t.version.equals(v)))
        .getSingleOrNull();
    return vr == null ? null : _decode(vr.json);
  }

  /// Saves an edit as a new version (or v1 for a new id). Returns the stored template.
  Future<OutputTemplate> save(OutputTemplate template) => db.transaction(() async {
    final now = nowUtc();
    final existing = await (db.select(db.templates)..where((t) => t.id.equals(template.id))).getSingleOrNull();
    final stored = existing == null
        ? template.copyWith(version: 1, updatedAt: now)
        : template.copyWith(version: existing.currentVersion + 1, updatedAt: now);
    if (existing == null) {
      await db.into(db.templates).insert(TemplatesCompanion.insert(
        id: stored.id,
        name: stored.name,
        currentVersion: stored.version,
        createdAt: stored.createdAt,
        updatedAt: now,
      ));
    } else {
      await (db.update(db.templates)..where((t) => t.id.equals(stored.id)))
          .write(TemplatesCompanion(name: Value(stored.name), currentVersion: Value(stored.version), updatedAt: Value(now)));
    }
    await db.into(db.templateVersions).insert(TemplateVersionsCompanion.insert(
      templateId: stored.id,
      version: stored.version,
      schemaVersion: stored.schemaVersion,
      json: jsonEncode(stored.toJson()),
      createdAt: now,
    ));
    return stored;
  });

  /// Phone-side cache of host templates; keeps the host's version numbers verbatim.
  Future<void> replaceCache(List<OutputTemplate> templates) => db.transaction(() async {
    await db.delete(db.templateVersions).go();
    await db.delete(db.templates).go();
    for (final t in templates) {
      await db.into(db.templates).insert(TemplatesCompanion.insert(
        id: t.id,
        name: t.name,
        currentVersion: t.version,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      ));
      await db.into(db.templateVersions).insert(TemplateVersionsCompanion.insert(
        templateId: t.id,
        version: t.version,
        schemaVersion: t.schemaVersion,
        json: jsonEncode(t.toJson()),
        createdAt: t.updatedAt,
      ));
    }
  });

  Future<void> delete(String id) => db.transaction(() async {
    await (db.delete(db.templateVersions)..where((t) => t.templateId.equals(id))).go();
    await (db.delete(db.templates)..where((t) => t.id.equals(id))).go();
  });

  /// Inserts sample templates only when none exist.
  Future<void> seedIfEmpty(List<OutputTemplate> samples) async {
    final count = await db.templates.count().getSingle();
    if (count > 0) return;
    for (final t in samples) {
      await save(t);
    }
  }

  Future<String> recordRunStart(String scanId, OutputTemplate t) async {
    final id = newId();
    await db.into(db.templateRuns).insert(TemplateRunsCompanion.insert(
      id: id,
      scanId: scanId,
      templateId: t.id,
      templateVersion: t.version,
      startedAt: nowUtc(),
      status: 'running',
    ));
    return id;
  }

  Future<void> recordRunEnd(String runId, {required String status, String summary = '', String? errorCode}) =>
      (db.update(db.templateRuns)..where((r) => r.id.equals(runId))).write(TemplateRunsCompanion(
        completedAt: Value(nowUtc()),
        status: Value(status),
        outputSummary: Value(summary),
        errorCode: Value(errorCode),
      ));
}
