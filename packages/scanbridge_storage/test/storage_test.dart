import 'dart:io';

import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:test/test.dart';

ScanRecord _scan(String id, String value, {String session = 's1', String device = 'd1'}) => ScanRecord(
  id: id,
  sessionId: session,
  deviceId: device,
  rawValue: value,
  capturedAt: DateTime.utc(2026, 10, 29, 10, 0, 0, 123),
  symbology: Symbology.ean13,
  deliveryStatus: DeliveryStatus.queued,
  values: const {'qty': '2'},
);

ScanSession _session(String id) => ScanSession(id: id, name: 'Session $id', createdAt: nowUtc(), updatedAt: nowUtc());

void main() {
  late ScanBridgeDatabase db;
  setUp(() => db = ScanBridgeDatabase.memory());
  tearDown(() => db.close());

  test('same scan id received twice creates one record', () async {
    final repo = ScanRepository(db);
    final (_, dup1) = await repo.receive(_scan('a', '000123'), sessionName: 'S');
    final (stored, dup2) = await repo.receive(_scan('a', '000123'), sessionName: 'S');
    expect(dup1, isFalse);
    expect(dup2, isTrue);
    expect(stored.rawValue, '000123');
    expect(await repo.forSession('s1'), hasLength(1));
  });

  test('capture writes scan and outbox atomically; ack completes it', () async {
    final scans = ScanRepository(db);
    final outbox = OutboxRepository(db);
    await scans.captureWithOutbox(_scan('a', '1'), _session('s1'));
    final due = await outbox.due(nowUtc());
    expect(due.single.scanId, 'a');
    await outbox.recordFailure(due.single, 'offline');
    expect(await outbox.due(nowUtc()), isEmpty, reason: 'backoff delays retry');
    await outbox.retryAll();
    expect(await outbox.due(nowUtc()), hasLength(1));
    await outbox.complete('a');
    expect(await outbox.watchPending().first, 0);
  });

  test('concurrent devices keep their own attribution', () async {
    final repo = ScanRepository(db);
    await repo.receive(_scan('a', '1', session: 'sA', device: 'phoneA'), sessionName: 'A');
    await repo.receive(_scan('b', '2', session: 'sB', device: 'phoneB'), sessionName: 'B');
    final a = await repo.forSession('sA');
    expect(a.single.deviceId, 'phoneA');
    expect((await repo.forSession('sB')).single.deviceId, 'phoneB');
  });

  test('values, timestamps (ms) and leading zeros survive round trip', () async {
    final repo = ScanRepository(db);
    await repo.receive(_scan('a', '000000123'), sessionName: 'S');
    final s = (await repo.byId('a'))!;
    expect(s.rawValue, '000000123');
    expect(s.values, {'qty': '2'});
    expect(s.capturedAt, DateTime.utc(2026, 10, 29, 10, 0, 0, 123));
    expect(s.capturedAt.isUtc, isTrue);
  });

  test('soft delete, undo and duplicate detection', () async {
    final repo = ScanRepository(db);
    await repo.receive(_scan('a', 'X'), sessionName: 'S');
    expect(await repo.valueExistsInSession('s1', 'X'), isTrue);
    await repo.softDelete(['a']);
    expect(await repo.forSession('s1'), isEmpty);
    expect(await repo.valueExistsInSession('s1', 'X'), isFalse);
    await repo.undoDelete(['a']);
    expect(await repo.forSession('s1'), hasLength(1));
  });

  test('sessions: count, archive, merge', () async {
    final scans = ScanRepository(db);
    final sessions = SessionRepository(db);
    await scans.receive(_scan('a', '1', session: 's1'), sessionName: 'One');
    await scans.receive(_scan('b', '2', session: 's2'), sessionName: 'Two');
    expect((await sessions.watch().first).map((s) => s.scanCount), [1, 1]);
    await sessions.merge('s1', ['s2']);
    final list = await sessions.watch().first;
    expect(list.single.scanCount, 2);
    await sessions.setArchived('s1', true);
    expect(await sessions.watch().first, isEmpty);
    expect(await sessions.watch(archived: true).first, hasLength(1));
  });

  test('template save creates versions and keeps history', () async {
    final repo = TemplateRepository(db);
    await repo.seedIfEmpty(SampleTemplates.all());
    expect(await repo.all(), hasLength(4));
    final t = (await repo.get(SampleTemplates.defaultId))!;
    final v2 = await repo.save(t.copyWith(name: 'Renamed'));
    expect(v2.version, 2);
    expect((await repo.get(t.id))!.name, 'Renamed');
    expect((await repo.get(t.id, version: 1))!.name, 'Barcode + Enter');
    await repo.seedIfEmpty(SampleTemplates.all());
    expect(await repo.all(), hasLength(4));
  });

  test('interrupted output is not reported as success after restart', () async {
    final repo = ScanRepository(db);
    await repo.receive(_scan('a', '1'), sessionName: 'S');
    await repo.setStatus('a', output: OutputStatus.pending);
    expect(await repo.markInterruptedOutput(), 1);
    expect((await repo.byId('a'))!.outputStatus, OutputStatus.failed);
  });

  test('file database persists across reopen and backs up', () async {
    final dir = Directory.systemTemp.createTempSync('sb');
    final file = File('${dir.path}/t.db');
    var fdb = ScanBridgeDatabase.open(file);
    await ScanRepository(fdb).captureWithOutbox(_scan('a', '1'), _session('s1'));
    await fdb.backupTo(File('${dir.path}/backup.db'));
    await fdb.close();
    fdb = ScanBridgeDatabase.open(file);
    expect(await OutboxRepository(fdb).due(nowUtc()), hasLength(1));
    await fdb.close();
    final restored = ScanBridgeDatabase.open(File('${dir.path}/backup.db'));
    expect(await ScanRepository(restored).forSession('s1'), hasLength(1));
    await restored.close();
    dir.deleteSync(recursive: true);
  });
}
