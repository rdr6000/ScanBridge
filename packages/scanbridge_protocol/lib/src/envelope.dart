import 'package:scanbridge_domain/scanbridge_domain.dart';

import 'limits.dart';
import 'signer.dart';

class MessageAuth {
  const MessageAuth(this.keyId, this.signature);
  final String keyId;
  final String signature;

  Map<String, Object?> toJson() => {'keyId': keyId, 'signature': signature};
}

/// Versioned message envelope. `payload` is a plain JSON map.
class Envelope {
  Envelope({
    required this.type,
    required this.payload,
    this.deviceId,
    String? messageId,
    DateTime? sentAt,
    this.protocolVersion = ProtocolLimits.version,
    this.auth,
  }) : messageId = messageId ?? newId(),
       sentAt = (sentAt ?? nowUtc()).toUtc();

  final int protocolVersion;
  final String messageId;
  final String type;
  final String? deviceId;
  final DateTime sentAt;
  final Map<String, Object?> payload;
  final MessageAuth? auth;

  Map<String, Object?> unsignedJson() => {
    'protocolVersion': protocolVersion,
    'messageId': messageId,
    'type': type,
    'deviceId': deviceId,
    'sentAt': sentAt.toIso8601String(),
    'payload': payload,
  };

  Map<String, Object?> toJson() => {...unsignedJson(), if (auth != null) 'auth': auth!.toJson()};

  Envelope signed(String keyId, List<int> key) => Envelope(
    type: type,
    payload: payload,
    deviceId: deviceId,
    messageId: messageId,
    sentAt: sentAt,
    protocolVersion: protocolVersion,
    auth: MessageAuth(keyId, Signer.sign(key, unsignedJson())),
  );

  bool verify(List<int> key) => auth != null && Signer.verify(key, unsignedJson(), auth!.signature);

  bool isFresh(DateTime now) => sentAt.difference(now).abs() <= ProtocolLimits.clockSkew;
}
