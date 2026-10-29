import 'dart:convert';

import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';
import 'package:test/test.dart';

void main() {
  final key = utf8.encode('secret-key');

  Envelope sample() => Envelope(
    type: MessageType.scanSubmit,
    deviceId: 'dev-1',
    payload: ScanSubmit(
      scanId: 'scan-1',
      sessionId: 'sess-1',
      sessionName: 'Shelf',
      rawValue: '00012345678905',
      symbology: Symbology.ean13,
      quantity: '1',
      capturedAt: DateTime.utc(2026, 10, 29),
      source: ScanSource.camera,
      values: const {'qty': '2'},
    ).toJson(),
  );

  test('canonical json is key-order independent', () {
    expect(canonicalJson({'b': 1, 'a': {'d': 2, 'c': 3}}), canonicalJson({'a': {'c': 3, 'd': 2}, 'b': 1}));
  });

  test('sign/encode/decode/verify round trip', () {
    final signed = sample().signed('dev-1', key);
    final decoded = EnvelopeCodec.decode(EnvelopeCodec.encode(signed)).valueOrNull!;
    expect(decoded.verify(key), isTrue);
    expect(decoded.verify(utf8.encode('wrong')), isFalse);
    final submit = ScanSubmit.fromJson(decoded.payload);
    expect(submit.rawValue, '00012345678905');
    expect(submit.values['qty'], '2');
  });

  test('tampered payload fails verification', () {
    final json = sample().signed('dev-1', key).toJson();
    (json['payload'] as Map)['rawValue'] = '999';
    expect(EnvelopeCodec.decode(jsonEncode(json)).valueOrNull!.verify(key), isFalse);
  });

  test('rejects oversize, malformed, unknown type and wrong version', () {
    expect(EnvelopeCodec.decode('x' * (ProtocolLimits.maxFrameBytes + 1)).isOk, isFalse);
    expect(EnvelopeCodec.decode('{nope').isOk, isFalse);
    final bad = sample().toJson()..['type'] = 'evil.type';
    expect(EnvelopeCodec.decode(jsonEncode(bad)).isOk, isFalse);
    final v2 = sample().toJson()..['protocolVersion'] = 2;
    expect(EnvelopeCodec.decode(jsonEncode(v2)).failureOrNull!.code, FailureCode.protocolVersionMismatch);
  });

  test('scan payload rejects float-like garbage quantity and empty value', () {
    final p = sample().payload;
    expect(() => ScanSubmit.fromJson({...p, 'quantity': '1e5'}), throwsA(isA<PayloadException>()));
    expect(() => ScanSubmit.fromJson({...p, 'rawValue': ''}), throwsA(isA<PayloadException>()));
  });

  test('replay guard rejects repeats and stays bounded', () {
    final g = ReplayGuard(2);
    expect(g.admit('a'), isTrue);
    expect(g.admit('a'), isFalse);
    g..admit('b')..admit('c');
    expect(g.admit('a'), isTrue);
  });

  test('pairing uri round trip and token normalization', () {
    final offer = PairingOffer(
      serverId: 'srv',
      serverName: 'Desk PC',
      hosts: const ['192.168.1.5', '10.0.0.2'],
      port: 57900,
      token: PairingOffer.generateToken(),
      expiresAt: DateTime.utc(2030),
    );
    final parsed = PairingOffer.tryParse(offer.toUri().toString())!;
    expect(parsed.hosts, offer.hosts);
    expect(parsed.token, offer.token);
    expect(parsed.serverName, 'Desk PC');
    expect(PairingOffer.normalizeToken('abcde-o1il2'), 'ABCDE01112');
    expect(PairingOffer.tryParse('https://example.com'), isNull);
  });

  test('both sides derive the same device secret', () {
    final a = Signer.deriveDeviceSecret(pairingToken: 'T', deviceId: 'd', clientNonce: 'c', serverNonce: 's');
    final b = Signer.deriveDeviceSecret(pairingToken: 'T', deviceId: 'd', clientNonce: 'c', serverNonce: 's');
    final other = Signer.deriveDeviceSecret(pairingToken: 'X', deviceId: 'd', clientNonce: 'c', serverNonce: 's');
    expect(a, b);
    expect(a, isNot(other));
  });

  test('freshness window', () {
    final e = Envelope(type: MessageType.deviceHeartbeat, payload: const {}, sentAt: DateTime.utc(2026, 1, 1));
    expect(e.isFresh(DateTime.utc(2026, 1, 1, 1)), isTrue);
    expect(e.isFresh(DateTime.utc(2026, 1, 3)), isFalse);
  });
}
