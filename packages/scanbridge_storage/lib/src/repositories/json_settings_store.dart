import 'dart:async';
import 'dart:convert';

import 'device_repository.dart';

/// Typed settings object persisted as one JSON document, with a change stream.
class JsonSettingsStore<T> {
  JsonSettingsStore(
    this.repo,
    this.key, {
    required T initial,
    required this.decode,
    required this.encode,
  }) : _current = initial;

  final SettingsRepository repo;
  final String key;
  final T Function(Map<String, Object?>) decode;
  final Map<String, Object?> Function(T) encode;
  final _controller = StreamController<T>.broadcast();
  T _current;

  T get current => _current;
  Stream<T> get changes => _controller.stream;

  /// Current value followed by every change; handy for StreamProviders.
  Stream<T> watch() async* {
    yield _current;
    yield* _controller.stream;
  }

  Future<void> load() async {
    final raw = await repo.get(key);
    if (raw == null) return;
    try {
      _current = decode((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      // Corrupt settings fall back to defaults rather than blocking startup.
    }
  }

  Future<void> update(T Function(T) change) async {
    _current = change(_current);
    await repo.set(key, jsonEncode(encode(_current)));
    _controller.add(_current);
  }

  /// Raw JSON value stored under another key (e.g. counters).
  Future<Map<String, Object?>> readJson(String otherKey) async {
    final raw = await repo.get(otherKey);
    return raw == null ? {} : (jsonDecode(raw) as Map).cast<String, Object?>();
  }

  Future<void> writeJson(String otherKey, Map<String, Object?> value) => repo.set(otherKey, jsonEncode(value));
}
