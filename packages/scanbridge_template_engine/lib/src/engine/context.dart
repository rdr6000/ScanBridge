import 'package:scanbridge_domain/scanbridge_domain.dart';

/// Reads a local CSV file for CSV_LOOKUP; implemented by the host.
abstract interface class CsvLookupSource {
  /// Returns the value of [valueColumn] in the first row whose [keyColumn] equals [key].
  Future<String?> lookup({required String path, required String keyColumn, required String key, required String valueColumn});
}

/// Inputs to one template run.
class ExecutionContext {
  const ExecutionContext({
    required this.barcode,
    required this.quantity,
    required this.capturedAt,
    required this.sessionName,
    required this.deviceName,
    required this.now,
    this.symbology = Symbology.unknown,
    this.values = const {},
    this.counters = const {},
    this.lookup,
  });

  factory ExecutionContext.forScan(ScanRecord scan, {
    required String sessionName,
    required String deviceName,
    Map<String, int> counters = const {},
    CsvLookupSource? lookup,
    DateTime? now,
  }) => ExecutionContext(
    barcode: scan.value,
    quantity: scan.quantity,
    capturedAt: scan.capturedAt,
    sessionName: sessionName,
    deviceName: deviceName,
    symbology: scan.symbology,
    values: scan.values,
    counters: counters,
    lookup: lookup,
    now: now ?? nowUtc(),
  );

  final String barcode;
  final String quantity;
  final DateTime capturedAt;
  final String sessionName;
  final String deviceName;
  final Symbology symbology;
  final DateTime now;

  /// Operator prompt answers keyed by component id.
  final Map<String, String> values;

  /// Persistent INCREMENT counters keyed by counter name.
  final Map<String, int> counters;
  final CsvLookupSource? lookup;
}
