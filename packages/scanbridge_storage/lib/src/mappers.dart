import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

import 'database.dart';

Map<String, String> decodeStringMap(String json) {
  try {
    final m = jsonDecode(json);
    return m is Map ? m.map((k, v) => MapEntry('$k', '$v')) : const {};
  } on FormatException {
    return const {};
  }
}

extension DeviceRowX on DeviceRow {
  Device toDomain() => Device(
    id: id,
    name: name,
    platform: platform,
    createdAt: createdAt,
    pairedAt: pairedAt,
    lastSeenAt: lastSeenAt,
    status: enumByName(DeviceStatus.values, status, DeviceStatus.pending),
    protocolVersion: protocolVersion,
    canSubmitScans: canSubmitScans,
  );
}

extension DeviceX on Device {
  DevicesCompanion toCompanion() => DevicesCompanion.insert(
    id: id,
    name: name,
    platform: platform,
    createdAt: createdAt,
    pairedAt: Value(pairedAt),
    lastSeenAt: Value(lastSeenAt),
    status: status.name,
    protocolVersion: Value(protocolVersion),
    canSubmitScans: Value(canSubmitScans),
  );
}

extension SessionRowX on SessionRow {
  ScanSession toDomain({int scanCount = 0}) => ScanSession(
    id: id,
    name: name,
    createdAt: createdAt,
    updatedAt: updatedAt,
    archivedAt: archivedAt,
    notes: notes,
    tags: (jsonDecode(tags) as List).map((e) => '$e').toList(),
    sourceDeviceId: sourceDeviceId,
    scanCount: scanCount,
  );
}

extension SessionX on ScanSession {
  SessionsCompanion toCompanion() => SessionsCompanion.insert(
    id: id,
    name: name,
    createdAt: createdAt,
    updatedAt: updatedAt,
    archivedAt: Value(archivedAt),
    notes: Value(notes),
    tags: Value(jsonEncode(tags)),
    sourceDeviceId: Value(sourceDeviceId),
  );
}

extension ScanRowX on ScanRow {
  ScanRecord toDomain() => ScanRecord(
    id: id,
    sessionId: sessionId,
    deviceId: deviceId,
    rawValue: rawValue,
    normalizedValue: normalizedValue == rawValue ? null : normalizedValue,
    symbology: Symbology.parse(symbology),
    quantity: quantity,
    capturedAt: capturedAt,
    receivedAt: receivedAt,
    source: enumByName(ScanSource.values, source, ScanSource.camera),
    validationStatus: enumByName(ValidationStatus.values, validationStatus, ValidationStatus.unchecked),
    deliveryStatus: enumByName(DeliveryStatus.values, deliveryStatus, DeliveryStatus.captured),
    outputStatus: enumByName(OutputStatus.values, outputStatus, OutputStatus.none),
    outputError: outputError,
    templateId: templateId,
    templateVersion: templateVersion,
    values: decodeStringMap(valuesJson),
    metadata: decodeStringMap(metadataJson),
    deletedAt: deletedAt,
  );
}

extension ScanX on ScanRecord {
  ScansCompanion toCompanion() => ScansCompanion.insert(
    id: id,
    sessionId: sessionId,
    deviceId: deviceId,
    rawValue: rawValue,
    normalizedValue: value,
    symbology: symbology.name,
    quantity: Value(quantity),
    capturedAt: capturedAt,
    receivedAt: Value(receivedAt),
    source: source.name,
    validationStatus: validationStatus.name,
    deliveryStatus: deliveryStatus.name,
    outputStatus: outputStatus.name,
    outputError: Value(outputError),
    templateId: Value(templateId),
    templateVersion: Value(templateVersion),
    valuesJson: Value(jsonEncode(values)),
    metadataJson: Value(jsonEncode(metadata)),
    deletedAt: Value(deletedAt),
  );
}

extension AuditRowX on AuditRow {
  AuditEvent toDomain() => AuditEvent(
    id: id,
    timestamp: timestamp,
    category: category,
    action: action,
    entityId: entityId,
    details: details,
  );
}
