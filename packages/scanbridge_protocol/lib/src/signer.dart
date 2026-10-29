import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'canonical_json.dart';

/// HMAC-SHA256 helpers. Keys are raw bytes; signatures are base64.
abstract final class Signer {
  static String sign(List<int> key, Map<String, Object?> unsigned) =>
      base64Encode(Hmac(sha256, key).convert(utf8.encode(canonicalJson(unsigned))).bytes);

  static bool verify(List<int> key, Map<String, Object?> unsigned, String signature) {
    final List<int> given;
    try {
      given = base64Decode(signature);
    } on FormatException {
      return false;
    }
    final expected = Hmac(sha256, key).convert(utf8.encode(canonicalJson(unsigned))).bytes;
    return constantTimeEquals(expected, given);
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Device secret both sides derive after pairing; never sent on the wire.
  static Uint8List deriveDeviceSecret({
    required String pairingToken,
    required String deviceId,
    required String clientNonce,
    required String serverNonce,
  }) {
    final input = utf8.encode('scanbridge/v1/device-secret|$deviceId|$clientNonce|$serverNonce');
    return Uint8List.fromList(Hmac(sha256, utf8.encode(pairingToken)).convert(input).bytes);
  }

  static String randomNonce([int bytes = 16]) {
    final r = Random.secure();
    return base64UrlEncode(List.generate(bytes, (_) => r.nextInt(256))).replaceAll('=', '');
  }
}
