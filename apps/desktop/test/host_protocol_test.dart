import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanbridge_desktop/src/host/host_controller.dart';
import 'package:scanbridge_desktop/src/host/host_settings.dart';
import 'package:scanbridge_desktop/src/host/output_service.dart';
import 'package:scanbridge_desktop/src/host/secret_store.dart';
import 'package:scanbridge_desktop/src/output/file_output.dart';
import 'package:scanbridge_desktop/src/output/keyboard_adapter.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

/// Records what would have been typed instead of injecting keys.
class FakeKeyboard implements KeyboardOutputAdapter {
  final typed = StringBuffer();
  @override
  Capability get capability => const Capability(CapabilityLevel.available, 'fake');
  @override
  String? checkTarget() => null;
  @override
  Future<String?> typeText(String text, {Duration perKeyDelay = Duration.zero}) async {
    typed.write(text);
    return null;
  }

  @override
  Future<String?> pressKey(KeyChord chord) async {
    typed.write('<$chord>');
    return null;
  }
}

/// Minimal phone-side protocol client.
class TestPhone {
  TestPhone._(this.socket, this.queue);
  final WebSocket socket;
  final StreamQueue<Envelope> queue;
  final deviceId = newId();
  List<int>? secret;

  static Future<TestPhone> connect(int port) async {
    final ws = await WebSocket.connect('ws://127.0.0.1:$port/ws');
    return TestPhone._(ws, StreamQueue(ws.map((f) => EnvelopeCodec.decode(f).valueOrNull!)));
  }

  Future<Envelope> next() => queue.next.timeout(const Duration(seconds: 5));

  Future<Envelope> nextOfType(String type) async {
    while (true) {
      final e = await next();
      if (e.type == type) return e;
    }
  }

  void send(Envelope e, {List<int>? key, String? keyId}) =>
      socket.add(EnvelopeCodec.encode(e.signed(keyId ?? deviceId, key ?? secret!)));

  Envelope _env(String type, Map<String, Object?> payload) => Envelope(type: type, deviceId: deviceId, payload: payload);

  Future<void> pair(String token, String serverNonce) async {
    final clientNonce = Signer.randomNonce();
    send(_env(MessageType.pairRequest, PairRequest(deviceName: 'Test phone', platform: 'android', clientNonce: clientNonce).toJson()),
        key: utf8.encode(token), keyId: pairingKeyId);
    final accept = await nextOfType(MessageType.pairAccept);
    expect(accept.verify(utf8.encode(token)), isTrue);
    secret = Signer.deriveDeviceSecret(pairingToken: token, deviceId: deviceId, clientNonce: clientNonce, serverNonce: serverNonce);
  }

  void submit(ScanSubmit s) => send(_env(MessageType.scanSubmit, s.toJson()));
}

ScanSubmit _scan(String id, {String value = '000123'}) => ScanSubmit(
  scanId: id,
  sessionId: 'session-1',
  sessionName: 'Shelf A',
  rawValue: value,
  symbology: Symbology.ean13,
  quantity: '1',
  capturedAt: DateTime.utc(2026, 10, 29),
  source: ScanSource.camera,
);

void main() {
  late ScanBridgeDatabase db;
  late HostController host;
  late FakeKeyboard keyboard;
  late Directory outDir;

  setUp(() async {
    db = ScanBridgeDatabase.memory();
    outDir = Directory.systemTemp.createTempSync('sb_out');
    keyboard = FakeKeyboard();
    final settings = HostSettingsStore(SettingsRepository(db));
    await settings.update((s) => s.copyWith(port: 0, outputDirectory: outDir.path));
    final templates = TemplateRepository(db);
    await templates.seedIfEmpty(SampleTemplates.all());
    final scans = ScanRepository(db);
    final sessions = SessionRepository(db);
    final devices = DeviceRepository(db);
    host = HostController(
      settings: settings,
      secrets: MemorySecretStore(),
      devices: devices,
      scans: scans,
      sessions: sessions,
      templates: templates,
      audit: AuditRepository(db),
      output: OutputService(
        scans: scans,
        sessions: sessions,
        devices: devices,
        templates: templates,
        settings: settings,
        keyboard: keyboard,
        files: FileOutput(outDir.path),
      ),
    );
    await host.init();
    await host.start();
    host.states.listen((s) {
      for (final p in s.pending) {
        host.decide(p, true);
      }
    });
  });

  tearDown(() async {
    await host.dispose();
    await db.close();
    outDir.deleteSync(recursive: true);
  });

  Future<TestPhone> pairedPhone() async {
    final offer = host.newOffer();
    final phone = await TestPhone.connect(host.state.port);
    final hello = ServerHello.fromJson((await phone.nextOfType(MessageType.serverHello)).payload);
    await phone.pair(offer.token, hello.nonce);
    phone.send(Envelope(type: MessageType.deviceStatus, deviceId: phone.deviceId, payload: const DeviceStatusPayload(deviceName: 'Test phone', platform: 'android').toJson()));
    final status = await phone.nextOfType(MessageType.deviceStatus);
    expect(status.verify(phone.secret!), isTrue, reason: 'host replies are signed with the device secret');
    return phone;
  }

  test('pair, submit, ack after persistence, output typed once; resend is idempotent', () async {
    final phone = await pairedPhone();
    phone.submit(_scan('scan-1'));
    final ack = ScanAck.fromJson((await phone.nextOfType(MessageType.scanAck)).payload);
    expect(ack.duplicateSubmit, isFalse);
    final delivery = DeliveryStatusPayload.fromJson((await phone.nextOfType(MessageType.deliveryStatus)).payload);
    if (delivery.outputStatus == OutputStatus.pending) {
      expect(DeliveryStatusPayload.fromJson((await phone.nextOfType(MessageType.deliveryStatus)).payload).outputStatus, OutputStatus.succeeded);
    }
    expect(keyboard.typed.toString(), '000123<enter>');

    phone.submit(_scan('scan-1'));
    final again = ScanAck.fromJson((await phone.nextOfType(MessageType.scanAck)).payload);
    expect(again.duplicateSubmit, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(keyboard.typed.toString(), '000123<enter>', reason: 'lost-ack resend must not type twice');
    expect(await ScanRepository(db).forSession('session-1'), hasLength(1));
    await phone.socket.close();
  });

  test('tampered or unsigned messages are rejected and the socket closed', () async {
    final phone = await pairedPhone();
    phone.send(Envelope(type: MessageType.scanSubmit, deviceId: phone.deviceId, payload: _scan('x').toJson()), key: utf8.encode('wrong'));
    final err = ErrorPayload.fromJson((await phone.nextOfType(MessageType.serverError)).payload);
    expect(err.code, FailureCode.authenticationFailed);
    expect(await ScanRepository(db).byId('x'), isNull);
  });

  test('wrong pairing code is rejected and consumes the offer', () async {
    host.newOffer();
    final phone = await TestPhone.connect(host.state.port);
    await phone.nextOfType(MessageType.serverHello);
    phone.send(
      Envelope(type: MessageType.pairRequest, deviceId: phone.deviceId, payload: const PairRequest(deviceName: 'x', platform: 'android', clientNonce: 'n').toJson()),
      key: utf8.encode('WRONGCODE0'),
      keyId: pairingKeyId,
    );
    final reject = ErrorPayload.fromJson((await phone.nextOfType(MessageType.pairReject)).payload);
    expect(reject.code, FailureCode.authenticationFailed);
    expect(host.state.offer, isNull);
  });

  test('invalid payload is rejected without storing; revoked phone cannot reconnect', () async {
    final phone = await pairedPhone();
    phone.send(Envelope(type: MessageType.scanSubmit, deviceId: phone.deviceId, payload: {..._scan('bad').toJson(), 'quantity': 'lots'}));
    final reject = ErrorPayload.fromJson((await phone.nextOfType(MessageType.scanReject)).payload);
    expect(reject.code, FailureCode.invalidScan);

    await host.revoke(phone.deviceId);
    await phone.nextOfType(MessageType.deviceRevoke);
    final again = await TestPhone.connect(host.state.port);
    await again.nextOfType(MessageType.serverHello);
    again.secret = phone.secret;
    again.send(Envelope(type: MessageType.deviceStatus, deviceId: phone.deviceId, payload: const DeviceStatusPayload(deviceName: 'x', platform: 'android').toJson()), keyId: phone.deviceId);
    expect(ErrorPayload.fromJson((await again.nextOfType(MessageType.serverError)).payload).code, FailureCode.authenticationFailed);
  });

  test('paused keyboard keeps the scan and reports paused, not success', () async {
    await host.settings.update((s) => s.copyWith(keyboardArmed: false));
    final phone = await pairedPhone();
    phone.submit(_scan('p1'));
    await phone.nextOfType(MessageType.scanAck);
    var status = OutputStatus.pending;
    while (status == OutputStatus.pending) {
      status = DeliveryStatusPayload.fromJson((await phone.nextOfType(MessageType.deliveryStatus)).payload).outputStatus;
    }
    expect(status, OutputStatus.paused);
    expect(keyboard.typed.toString(), isEmpty);
    expect((await ScanRepository(db).byId('p1'))!.deliveryStatus, DeliveryStatus.received);
  });

  test('file output is confined to the output folder', () async {
    final files = FileOutput(outDir.path);
    expect(files.resolve('a/b.csv'), isNotNull);
    expect(files.resolve('../escape.csv'), isNull);
    expect(files.resolve(Platform.isWindows ? r'C:\Windows\x.csv' : '/etc/x.csv'), isNull);
    final err = await files.append(const FileAppendAction(path: 'out.csv', cells: ['000123', 'a,b', '=1'], csv: true, header: ['v', 'x', 'f']), const CsvOptions());
    expect(err, isNull);
    expect(File('${outDir.path}/out.csv').readAsStringSync(), 'v,x,f\r\n000123,"a,b",\'=1\r\n');
  });
}
