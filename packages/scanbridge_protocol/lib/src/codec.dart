import 'dart:convert';

import 'package:scanbridge_domain/scanbridge_domain.dart';

import 'envelope.dart';
import 'limits.dart';
import 'message_types.dart';

/// Parses and schema-checks inbound frames. Never throws.
abstract final class EnvelopeCodec {
  static String encode(Envelope e) => jsonEncode(e.toJson());

  static Result<Envelope> decode(Object? frame) {
    if (frame is! String) return _bad('binary frames are not supported');
    if (frame.length > ProtocolLimits.maxFrameBytes) return _bad('frame too large');
    final Object? json;
    try {
      json = jsonDecode(frame);
    } on FormatException {
      return _bad('malformed JSON');
    }
    if (json is! Map<String, Object?>) return _bad('envelope must be an object');
    final version = json['protocolVersion'];
    if (version is! int) return _bad('protocolVersion missing');
    if (version != ProtocolLimits.version) {
      return Err(AppFailure(
        FailureCode.protocolVersionMismatch,
        'Unsupported protocol version $version',
        nextStep: 'Update ScanBridge on both devices.',
      ));
    }
    final type = json['type'];
    final messageId = json['messageId'];
    final sentAt = DateTime.tryParse(json['sentAt'] as String? ?? '');
    final payload = json['payload'];
    if (type is! String || !MessageType.all.contains(type)) return _bad('unknown type');
    if (messageId is! String || messageId.length > 64) return _bad('bad messageId');
    if (sentAt == null) return _bad('bad sentAt');
    if (payload is! Map<String, Object?>) return _bad('payload must be an object');
    final deviceId = json['deviceId'];
    if (deviceId != null && (deviceId is! String || deviceId.length > 64)) return _bad('bad deviceId');
    final auth = json['auth'];
    MessageAuth? parsedAuth;
    if (auth is Map) {
      final keyId = auth['keyId'];
      final sig = auth['signature'];
      if (keyId is! String || sig is! String) return _bad('bad auth');
      parsedAuth = MessageAuth(keyId, sig);
    }
    return Ok(Envelope(
      type: type,
      payload: payload,
      deviceId: deviceId as String?,
      messageId: messageId,
      sentAt: sentAt,
      protocolVersion: version,
      auth: parsedAuth,
    ));
  }

  static Err<Envelope> _bad(String why) =>
      Err(AppFailure(FailureCode.unknownFailure, 'Invalid message: $why'));
}

/// Bounded LRU of seen message ids to reject replays.
class ReplayGuard {
  ReplayGuard([this.capacity = ProtocolLimits.replayCacheSize]);

  final int capacity;
  final _seen = <String>{};

  /// Returns false when [messageId] was already seen.
  bool admit(String messageId) {
    if (!_seen.add(messageId)) return false;
    if (_seen.length > capacity) _seen.remove(_seen.first);
    return true;
  }
}
