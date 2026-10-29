import 'dart:math';

import 'limits.dart';

/// Short-lived one-time pairing offer shown as a QR code and a typed code.
class PairingOffer {
  const PairingOffer({
    required this.serverId,
    required this.serverName,
    required this.hosts,
    required this.port,
    required this.token,
    required this.expiresAt,
  });

  final String serverId;
  final String serverName;
  final List<String> hosts;
  final int port;
  final String token;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  static const scheme = 'scanbridge';

  /// `scanbridge://pair?v=1&h=ip1,ip2&p=57900&t=TOKEN&n=Name&id=serverId`
  Uri toUri() => Uri(scheme: scheme, host: 'pair', queryParameters: {
    'v': '${ProtocolLimits.version}',
    'h': hosts.join(','),
    'p': '$port',
    't': token,
    'n': serverName,
    'id': serverId,
  });

  /// Parses a scanned QR. Expiry is not encoded; the host enforces it.
  static PairingOffer? tryParse(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || uri.scheme != scheme || uri.host != 'pair') return null;
    final q = uri.queryParameters;
    final port = int.tryParse(q['p'] ?? '');
    final hosts = (q['h'] ?? '').split(',').where((h) => h.isNotEmpty).toList();
    final token = q['t'] ?? '';
    if (q['v'] != '${ProtocolLimits.version}' || port == null || hosts.isEmpty || token.isEmpty) return null;
    return PairingOffer(
      serverId: q['id'] ?? '',
      serverName: q['n'] ?? 'ScanBridge',
      hosts: hosts,
      port: port,
      token: normalizeToken(token),
      expiresAt: DateTime.utc(9999),
    );
  }

  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// 10 Crockford base32 chars (50 bits); readable for manual entry.
  static String generateToken([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(10, (_) => _alphabet[r.nextInt(_alphabet.length)]).join();
  }

  /// Tolerates lowercase, spaces, dashes and look-alike letters when typed.
  static String normalizeToken(String input) => input
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]'), '')
      .replaceAll('O', '0')
      .replaceAll(RegExp('[IL]'), '1');

  /// Formats `ABCDE12345` as `ABCDE-12345` for display.
  static String displayToken(String token) =>
      token.length == 10 ? '${token.substring(0, 5)}-${token.substring(5)}' : token;
}
