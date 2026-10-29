import 'package:scanbridge_domain/scanbridge_domain.dart';

import 'limits.dart';

/// Thrown only inside payload parsing; callers convert it to a rejection.
class PayloadException implements Exception {
  PayloadException(this.message);
  final String message;
  @override
  String toString() => message;
}

String _str(Map<String, Object?> j, String key, {int max = ProtocolLimits.maxNameLength, bool optional = false}) {
  final v = j[key];
  if (v == null && optional) return '';
  if (v is! String) throw PayloadException('$key must be a string');
  if (v.length > max) throw PayloadException('$key too long');
  return v;
}

DateTime _time(Map<String, Object?> j, String key) =>
    DateTime.tryParse(_str(j, key, max: 40))?.toUtc() ?? (throw PayloadException('$key must be ISO-8601'));

class ServerHello {
  const ServerHello({required this.serverId, required this.serverName, required this.nonce, required this.serverTime});
  final String serverId;
  final String serverName;
  final String nonce;
  final DateTime serverTime;

  Map<String, Object?> toJson() =>
      {'serverId': serverId, 'serverName': serverName, 'nonce': nonce, 'serverTime': serverTime.toIso8601String()};

  factory ServerHello.fromJson(Map<String, Object?> j) => ServerHello(
    serverId: _str(j, 'serverId'),
    serverName: _str(j, 'serverName'),
    nonce: _str(j, 'nonce'),
    serverTime: _time(j, 'serverTime'),
  );
}

class PairRequest {
  const PairRequest({required this.deviceName, required this.platform, required this.clientNonce});
  final String deviceName;
  final String platform;
  final String clientNonce;

  Map<String, Object?> toJson() => {'deviceName': deviceName, 'platform': platform, 'clientNonce': clientNonce};

  factory PairRequest.fromJson(Map<String, Object?> j) => PairRequest(
    deviceName: _str(j, 'deviceName'),
    platform: _str(j, 'platform', max: 32),
    clientNonce: _str(j, 'clientNonce', max: 64),
  );
}

class PairAccept {
  const PairAccept({required this.serverId, required this.serverName, required this.serverNonce});
  final String serverId;
  final String serverName;
  final String serverNonce;

  Map<String, Object?> toJson() => {'serverId': serverId, 'serverName': serverName, 'serverNonce': serverNonce};

  factory PairAccept.fromJson(Map<String, Object?> j) => PairAccept(
    serverId: _str(j, 'serverId'),
    serverName: _str(j, 'serverName'),
    serverNonce: _str(j, 'serverNonce', max: 64),
  );
}

/// Client status/handshake; first authenticated message on each connection.
class DeviceStatusPayload {
  const DeviceStatusPayload({required this.deviceName, required this.platform, this.pendingScans = 0});
  final String deviceName;
  final String platform;
  final int pendingScans;

  Map<String, Object?> toJson() => {'deviceName': deviceName, 'platform': platform, 'pendingScans': pendingScans};

  factory DeviceStatusPayload.fromJson(Map<String, Object?> j) => DeviceStatusPayload(
    deviceName: _str(j, 'deviceName'),
    platform: _str(j, 'platform', max: 32),
    pendingScans: (j['pendingScans'] as int?) ?? 0,
  );
}

class ScanSubmit {
  const ScanSubmit({
    required this.scanId,
    required this.sessionId,
    required this.sessionName,
    required this.rawValue,
    required this.symbology,
    required this.quantity,
    required this.capturedAt,
    required this.source,
    this.templateId,
    this.templateVersion,
    this.values = const {},
  });

  final String scanId;
  final String sessionId;
  final String sessionName;
  final String rawValue;
  final Symbology symbology;
  final String quantity;
  final DateTime capturedAt;
  final ScanSource source;
  final String? templateId;
  final int? templateVersion;
  final Map<String, String> values;

  factory ScanSubmit.fromRecord(ScanRecord s, String sessionName) => ScanSubmit(
    scanId: s.id,
    sessionId: s.sessionId,
    sessionName: sessionName,
    rawValue: s.rawValue,
    symbology: s.symbology,
    quantity: s.quantity,
    capturedAt: s.capturedAt,
    source: s.source,
    templateId: s.templateId,
    templateVersion: s.templateVersion,
    values: s.values,
  );

  Map<String, Object?> toJson() => {
    'scanId': scanId,
    'sessionId': sessionId,
    'sessionName': sessionName,
    'rawValue': rawValue,
    'symbology': symbology.name,
    'quantity': quantity,
    'capturedAt': capturedAt.toUtc().toIso8601String(),
    'source': source.name,
    'templateId': templateId,
    'templateVersion': templateVersion,
    'values': values,
  };

  factory ScanSubmit.fromJson(Map<String, Object?> j) {
    final rawValues = j['values'];
    if (rawValues != null && rawValues is! Map) throw PayloadException('values must be an object');
    final values = <String, String>{};
    if (rawValues is Map) {
      if (rawValues.length > ProtocolLimits.maxPromptValues) throw PayloadException('too many values');
      rawValues.forEach((k, v) {
        if (v is! String || v.length > ProtocolLimits.maxValueLength) throw PayloadException('bad value for $k');
        values['$k'] = v;
      });
    }
    final quantity = _str(j, 'quantity', max: 32);
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(quantity)) throw PayloadException('quantity must be a decimal string');
    final version = j['templateVersion'];
    if (version != null && version is! int) throw PayloadException('templateVersion must be int');
    final raw = _str(j, 'rawValue', max: ProtocolLimits.maxValueLength);
    if (raw.isEmpty) throw PayloadException('rawValue is empty');
    final templateId = _str(j, 'templateId', max: 64, optional: true);
    return ScanSubmit(
      scanId: _str(j, 'scanId', max: 64),
      sessionId: _str(j, 'sessionId', max: 64),
      sessionName: _str(j, 'sessionName'),
      rawValue: raw,
      symbology: Symbology.parse(j['symbology'] as String?),
      quantity: quantity,
      capturedAt: _time(j, 'capturedAt'),
      source: enumByName(ScanSource.values, j['source'] as String?, ScanSource.camera),
      templateId: templateId.isEmpty ? null : templateId,
      templateVersion: version as int?,
      values: values,
    );
  }
}

class ScanAck {
  const ScanAck({required this.scanId, required this.duplicateSubmit, required this.receivedAt});
  final String scanId;

  /// True when this scanId was already stored (lost-ack resend).
  final bool duplicateSubmit;
  final DateTime receivedAt;

  Map<String, Object?> toJson() =>
      {'scanId': scanId, 'duplicateSubmit': duplicateSubmit, 'receivedAt': receivedAt.toIso8601String()};

  factory ScanAck.fromJson(Map<String, Object?> j) => ScanAck(
    scanId: _str(j, 'scanId', max: 64),
    duplicateSubmit: j['duplicateSubmit'] == true,
    receivedAt: _time(j, 'receivedAt'),
  );
}

/// Shared shape for scan.reject, pair.reject and server.error.
class ErrorPayload {
  const ErrorPayload({required this.code, required this.message, this.scanId});
  final FailureCode code;
  final String message;
  final String? scanId;

  Map<String, Object?> toJson() => {'code': code.name, 'message': message, 'scanId': ?scanId};

  factory ErrorPayload.fromJson(Map<String, Object?> j) => ErrorPayload(
    code: enumByName(FailureCode.values, j['code'] as String?, FailureCode.unknownFailure),
    message: _str(j, 'message', max: 512, optional: true),
    scanId: j['scanId'] as String?,
  );
}

class DeliveryStatusPayload {
  const DeliveryStatusPayload({required this.scanId, required this.outputStatus, this.error});
  final String scanId;
  final OutputStatus outputStatus;
  final String? error;

  Map<String, Object?> toJson() => {'scanId': scanId, 'outputStatus': outputStatus.name, 'error': ?error};

  factory DeliveryStatusPayload.fromJson(Map<String, Object?> j) => DeliveryStatusPayload(
    scanId: _str(j, 'scanId', max: 64),
    outputStatus: enumByName(OutputStatus.values, j['outputStatus'] as String?, OutputStatus.none),
    error: j['error'] as String?,
  );
}

class SessionUpdatePayload {
  const SessionUpdatePayload({required this.sessionId, required this.name});
  final String sessionId;
  final String name;

  Map<String, Object?> toJson() => {'sessionId': sessionId, 'name': name};

  factory SessionUpdatePayload.fromJson(Map<String, Object?> j) =>
      SessionUpdatePayload(sessionId: _str(j, 'sessionId', max: 64), name: _str(j, 'name'));
}

/// Host -> phone: templates with their current versions; phones collect prompt values.
class TemplateListPayload {
  const TemplateListPayload({required this.templates, this.activeTemplateId});
  final List<Map<String, Object?>> templates;
  final String? activeTemplateId;

  Map<String, Object?> toJson() => {'templates': templates, 'activeTemplateId': activeTemplateId};

  factory TemplateListPayload.fromJson(Map<String, Object?> j) => TemplateListPayload(
    templates: [for (final t in (j['templates'] as List? ?? const [])) (t as Map).cast<String, Object?>()],
    activeTemplateId: j['activeTemplateId'] as String?,
  );
}
