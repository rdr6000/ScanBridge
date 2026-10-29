import 'dart:math';

import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:test/test.dart';

ScanRecord _scan(String value) => ScanRecord(
  id: 'id-$value',
  sessionId: 's1',
  deviceId: 'd1',
  rawValue: value,
  capturedAt: DateTime.utc(2026, 10, 29, 12),
  symbology: Symbology.ean13,
);

void main() {
  group('CsvEncoder', () {
    const csv = CsvEncoder();

    test('keeps leading zeros and Unicode as text', () {
      expect(csv.encodeCell('000123'), '000123');
      expect(csv.encodeCell('café ✓'), 'café ✓');
    });

    test('quotes commas, quotes and newlines', () {
      expect(csv.encodeCell('a,b'), '"a,b"');
      expect(csv.encodeCell('say "hi"'), '"say ""hi"""');
      expect(csv.encodeCell('line1\nline2'), '"line1\nline2"');
    });

    test('guards formula injection by default', () {
      for (final v in ['=1+1', '+1', '-1', '@SUM(A1)']) {
        expect(csv.encodeCell(v), "'$v");
      }
      expect(const CsvEncoder(CsvOptions(formulaGuard: false)).encodeCell('=1'), '=1');
    });

    test('writes BOM, header and CRLF', () {
      final out = const CsvEncoder(CsvOptions(utf8Bom: true)).encode(['a'], [['1']]);
      expect(out, '﻿a\r\n1\r\n');
    });
  });

  group('SessionExporter', () {
    final session = ScanSession(id: 's1', name: 'Shelf', createdAt: DateTime.utc(2026), updatedAt: DateTime.utc(2026));

    test('csv round trip preserves tricky values', () {
      final out = const SessionExporter().export(ExportFormat.csv, session, [_scan('000123'), _scan('a,"b"\nc')]);
      expect(out, contains(',000123,'));
      expect(out, contains('"a,""b""\nc"'));
    });

    test('txt flattens newlines; json is valid', () {
      expect(const SessionExporter().export(ExportFormat.txt, session, [_scan('a\nb')]), 'a b');
      expect(const SessionExporter().export(ExportFormat.json, session, [_scan('1')]), contains('"value": "1"'));
    });
  });

  group('ScanValidator', () {
    test('format filter, length, prefix and regex', () {
      final v = ScanValidator(const ScanRules(
        allowedFormats: {Symbology.ean13},
        minLength: 3,
        maxLength: 13,
        requiredPrefix: '0',
        pattern: r'^\d+$',
      ));
      expect(v.validate('0123', Symbology.ean13).status, ValidationStatus.valid);
      expect(v.validate('0123', Symbology.qrCode).status, ValidationStatus.invalid);
      expect(v.validate('01', Symbology.ean13).status, ValidationStatus.invalid);
      expect(v.validate('123', Symbology.ean13).status, ValidationStatus.invalid);
      expect(v.validate('0abc', Symbology.ean13).status, ValidationStatus.invalid);
    });

    test('duplicate policy', () {
      ValidationStatus check(DuplicatePolicy p) =>
          ScanValidator(ScanRules(duplicatePolicy: p)).validate('1', Symbology.unknown, isDuplicate: true).status;
      expect(check(DuplicatePolicy.allow), ValidationStatus.valid);
      expect(check(DuplicatePolicy.warn), ValidationStatus.duplicate);
      expect(check(DuplicatePolicy.block), ValidationStatus.invalid);
    });

    test('invalid regex rejects instead of accepting everything', () {
      final v = ScanValidator(const ScanRules(pattern: '('));
      expect(v.hasInvalidPattern, isTrue);
      expect(v.validate('x', Symbology.unknown).status, ValidationStatus.invalid);
    });

    test('rules json round trip', () {
      const rules = ScanRules(allowedFormats: {Symbology.qrCode}, minLength: 2, duplicatePolicy: DuplicatePolicy.block);
      final back = ScanRules.fromJson(rules.toJson());
      expect(back.allowedFormats, {Symbology.qrCode});
      expect(back.minLength, 2);
      expect(back.duplicatePolicy, DuplicatePolicy.block);
    });
  });

  test('Backoff is bounded and grows', () {
    const b = Backoff(base: Duration(seconds: 1), max: Duration(seconds: 30));
    final r = Random(1);
    expect(b.delayFor(0, r).inMilliseconds, inInclusiveRange(500, 1000));
    expect(b.delayFor(50, r).inMilliseconds, inInclusiveRange(15000, 30000));
  });
}
