import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';

/// Per-device HMAC secrets and the host identity, in OS secure storage.
abstract interface class SecretStore {
  Future<List<int>?> deviceSecret(String deviceId);
  Future<void> setDeviceSecret(String deviceId, List<int> secret);
  Future<void> deleteDeviceSecret(String deviceId);
  Future<String> serverId();
}

/// Windows Credential Manager/DPAPI, macOS Keychain, Linux libsecret.
class SecureSecretStore implements SecretStore {
  SecureSecretStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  // Secrets are cached so message verification does not hit the OS store each time.
  final _cache = <String, List<int>>{};

  @override
  Future<List<int>?> deviceSecret(String deviceId) async {
    final cached = _cache[deviceId];
    if (cached != null) return cached;
    final v = await _s.read(key: 'device.$deviceId');
    if (v == null) return null;
    return _cache[deviceId] = base64Decode(v);
  }

  @override
  Future<void> setDeviceSecret(String deviceId, List<int> secret) async {
    _cache[deviceId] = secret;
    await _s.write(key: 'device.$deviceId', value: base64Encode(secret));
  }

  @override
  Future<void> deleteDeviceSecret(String deviceId) async {
    _cache.remove(deviceId);
    await _s.delete(key: 'device.$deviceId');
  }

  @override
  Future<String> serverId() async {
    final existing = await _s.read(key: 'server.id');
    if (existing != null) return existing;
    final id = newId();
    await _s.write(key: 'server.id', value: id);
    return id;
  }
}

/// Test/in-memory implementation.
class MemorySecretStore implements SecretStore {
  final _m = <String, List<int>>{};
  final _id = newId();

  @override
  Future<List<int>?> deviceSecret(String deviceId) async => _m[deviceId];
  @override
  Future<void> setDeviceSecret(String deviceId, List<int> secret) async => _m[deviceId] = secret;
  @override
  Future<void> deleteDeviceSecret(String deviceId) async => _m.remove(deviceId);
  @override
  Future<String> serverId() async => _id;
}
