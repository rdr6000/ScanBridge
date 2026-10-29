import 'dart:convert';

import '../entities.dart';
import 'csv_encoder.dart';

enum ExportFormat {
  csv('csv'),
  tsv('tsv'),
  json('json'),
  txt('txt');

  const ExportFormat(this.extension);
  final String extension;
}

/// Renders scans of a session into a portable text format.
class SessionExporter {
  const SessionExporter({this.csvOptions = const CsvOptions()});

  final CsvOptions csvOptions;

  static const header = [
    'id', 'session', 'value', 'raw_value', 'symbology', 'quantity', 'captured_at', //
    'device_id', 'source', 'validation', 'delivery', 'output', 'values',
  ];

  List<String> row(ScanSession session, ScanRecord s) => [
    s.id,
    session.name,
    s.value,
    s.rawValue,
    s.symbology.name,
    s.quantity,
    s.capturedAt.toUtc().toIso8601String(),
    s.deviceId,
    s.source.name,
    s.validationStatus.name,
    s.deliveryStatus.name,
    s.outputStatus.name,
    s.values.isEmpty ? '' : jsonEncode(s.values),
  ];

  String export(ExportFormat format, ScanSession session, List<ScanRecord> scans) {
    Iterable<List<String>> rows() => scans.map((s) => row(session, s));
    return switch (format) {
      ExportFormat.csv => CsvEncoder(csvOptions).encode(header, rows()),
      ExportFormat.tsv => CsvEncoder(csvOptions.withDelimiter('\t')).encode(header, rows()),
      ExportFormat.json => const JsonEncoder.withIndent('  ').convert({
        'session': {'id': session.id, 'name': session.name, 'createdAt': session.createdAt.toIso8601String()},
        'scans': [for (final r in rows()) Map.fromIterables(header, r)],
      }),
      ExportFormat.txt => scans.map((s) => s.value.replaceAll(RegExp(r'[\r\n]+'), ' ')).join('\n'),
    };
  }
}
