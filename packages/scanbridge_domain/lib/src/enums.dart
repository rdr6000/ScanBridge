/// Wire-stable enums. `name` values are persisted and sent over the protocol.
library;

enum ScanSource { camera, manual, hardware, imported }

/// Acquisition/delivery state of a scan from the phone's point of view.
enum DeliveryStatus { captured, queued, received, rejected, failed, localOnly }

/// Output state on the desktop host, kept separate from delivery.
enum OutputStatus { none, pending, succeeded, failed, skipped, paused }

enum ValidationStatus { valid, invalid, duplicate, unchecked }

enum DeviceStatus { pending, paired, revoked }

enum Symbology {
  ean8,
  ean13,
  upcA,
  upcE,
  code128,
  code39,
  code93,
  itf,
  codabar,
  qrCode,
  dataMatrix,
  pdf417,
  aztec,
  unknown;

  static Symbology parse(String? value) => Symbology.values.firstWhere(
    (s) => s.name == value,
    orElse: () => Symbology.unknown,
  );

  bool get is2d => const {qrCode, dataMatrix, pdf417, aztec}.contains(this);
}

T enumByName<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);
