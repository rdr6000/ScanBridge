import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

/// A paired desktop host: where to connect and the derived device secret.
class HostLink {
  const HostLink({required this.serverId, required this.serverName, required this.hosts, required this.port, required this.secret});

  final String serverId;
  final String serverName;
  final List<String> hosts;
  final int port;
  final List<int> secret;

  HostLink withHosts(List<String> h) => HostLink(serverId: serverId, serverName: serverName, hosts: h, port: port, secret: secret);

  Map<String, Object?> toJson() => {
    'serverId': serverId,
    'serverName': serverName,
    'hosts': hosts,
    'port': port,
    'secret': base64Encode(secret),
  };

  factory HostLink.fromJson(Map<String, Object?> j) => HostLink(
    serverId: j['serverId'] as String,
    serverName: j['serverName'] as String,
    hosts: (j['hosts'] as List).cast<String>(),
    port: j['port'] as int,
    secret: base64Decode(j['secret'] as String),
  );
}

/// Android Keystore / iOS Keychain backed credentials.
class CredentialStore {
  CredentialStore([FlutterSecureStorage? s]) : _s = s ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  Future<String> deviceId() async {
    final existing = await _s.read(key: 'device.id');
    if (existing != null) return existing;
    final id = newId();
    await _s.write(key: 'device.id', value: id);
    return id;
  }

  Future<HostLink?> link() async {
    final raw = await _s.read(key: 'host.link');
    if (raw == null) return null;
    try {
      return HostLink.fromJson((jsonDecode(raw) as Map).cast());
    } on Object {
      return null;
    }
  }

  Future<void> saveLink(HostLink link) => _s.write(key: 'host.link', value: jsonEncode(link.toJson()));

  Future<void> forgetLink() => _s.delete(key: 'host.link');
}
