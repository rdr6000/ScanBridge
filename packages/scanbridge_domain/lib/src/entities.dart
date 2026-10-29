import 'enums.dart';

/// Paired phone/tablet as known by the desktop host.
class Device {
  const Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.createdAt,
    required this.status,
    this.pairedAt,
    this.lastSeenAt,
    this.protocolVersion = 1,
    this.canSubmitScans = true,
  });

  final String id;
  final String name;
  final String platform;
  final DateTime createdAt;
  final DateTime? pairedAt;
  final DateTime? lastSeenAt;
  final DeviceStatus status;
  final int protocolVersion;
  final bool canSubmitScans;

  Device copyWith({String? name, DateTime? lastSeenAt, DeviceStatus? status, bool? canSubmitScans}) => Device(
    id: id,
    name: name ?? this.name,
    platform: platform,
    createdAt: createdAt,
    pairedAt: pairedAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    status: status ?? this.status,
    protocolVersion: protocolVersion,
    canSubmitScans: canSubmitScans ?? this.canSubmitScans,
  );
}

class ScanSession {
  const ScanSession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.notes = '',
    this.tags = const [],
    this.sourceDeviceId,
    this.scanCount = 0,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final String notes;
  final List<String> tags;
  final String? sourceDeviceId;

  /// Derived from scans; not persisted.
  final int scanCount;

  bool get isArchived => archivedAt != null;

  ScanSession copyWith({String? name, String? notes, List<String>? tags, DateTime? updatedAt, DateTime? Function()? archivedAt}) =>
      ScanSession(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archivedAt: archivedAt != null ? archivedAt() : this.archivedAt,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        sourceDeviceId: sourceDeviceId,
        scanCount: scanCount,
      );
}

/// One acquired code. Values are always strings to keep leading zeros.
class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.sessionId,
    required this.deviceId,
    required this.rawValue,
    required this.capturedAt,
    this.symbology = Symbology.unknown,
    this.normalizedValue,
    this.quantity = '1',
    this.source = ScanSource.camera,
    this.receivedAt,
    this.validationStatus = ValidationStatus.unchecked,
    this.deliveryStatus = DeliveryStatus.captured,
    this.outputStatus = OutputStatus.none,
    this.outputError,
    this.templateId,
    this.templateVersion,
    this.values = const {},
    this.metadata = const {},
    this.deletedAt,
  });

  final String id;
  final String sessionId;
  final String deviceId;
  final String rawValue;
  final String? normalizedValue;
  final Symbology symbology;
  final String quantity;
  final DateTime capturedAt;
  final DateTime? receivedAt;
  final ScanSource source;
  final ValidationStatus validationStatus;
  final DeliveryStatus deliveryStatus;
  final OutputStatus outputStatus;
  final String? outputError;
  final String? templateId;
  final int? templateVersion;

  /// Operator answers collected for template prompts, keyed by component id.
  final Map<String, String> values;
  final Map<String, String> metadata;
  final DateTime? deletedAt;

  String get value => normalizedValue ?? rawValue;

  ScanRecord copyWith({
    String? rawValue,
    String? quantity,
    DateTime? receivedAt,
    ValidationStatus? validationStatus,
    DeliveryStatus? deliveryStatus,
    OutputStatus? outputStatus,
    String? Function()? outputError,
    Map<String, String>? metadata,
    DateTime? Function()? deletedAt,
  }) => ScanRecord(
    id: id,
    sessionId: sessionId,
    deviceId: deviceId,
    rawValue: rawValue ?? this.rawValue,
    normalizedValue: normalizedValue,
    symbology: symbology,
    quantity: quantity ?? this.quantity,
    capturedAt: capturedAt,
    receivedAt: receivedAt ?? this.receivedAt,
    source: source,
    validationStatus: validationStatus ?? this.validationStatus,
    deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    outputStatus: outputStatus ?? this.outputStatus,
    outputError: outputError != null ? outputError() : this.outputError,
    templateId: templateId,
    templateVersion: templateVersion,
    values: values,
    metadata: metadata ?? this.metadata,
    deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
  );
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.action,
    this.entityId,
    this.details = '',
  });

  final String id;
  final DateTime timestamp;
  final String category;
  final String action;
  final String? entityId;

  /// Already redacted; never contains secrets.
  final String details;
}
