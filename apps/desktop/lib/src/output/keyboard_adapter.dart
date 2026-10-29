import 'dart:io';

import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

import 'windows_keyboard.dart';

enum CapabilityLevel { available, limited, permissionRequired, unavailable }

/// Capability plus a human-readable reason; shown in UI, never hidden.
class Capability {
  const Capability(this.level, this.reason);
  final CapabilityLevel level;
  final String reason;
  bool get usable => level == CapabilityLevel.available || level == CapabilityLevel.limited;
}

/// Platform-neutral keyboard injection. Implementations must return an error
/// string unless the OS accepted every event; they never fake success.
abstract interface class KeyboardOutputAdapter {
  Capability get capability;

  /// Optional pre-flight check of the current target (e.g. elevated window).
  String? checkTarget();

  Future<String?> typeText(String text, {Duration perKeyDelay = Duration.zero});

  Future<String?> pressKey(KeyChord chord);
}

/// Used where no native adapter exists yet (macOS, Linux in this build).
class UnsupportedKeyboardAdapter implements KeyboardOutputAdapter {
  const UnsupportedKeyboardAdapter(this.reason);
  final String reason;

  @override
  Capability get capability => Capability(CapabilityLevel.unavailable, reason);

  @override
  String? checkTarget() => reason;

  @override
  Future<String?> typeText(String text, {Duration perKeyDelay = Duration.zero}) async => reason;

  @override
  Future<String?> pressKey(KeyChord chord) async => reason;
}

KeyboardOutputAdapter createKeyboardAdapter() {
  if (Platform.isWindows) return WindowsKeyboardAdapter();
  if (Platform.isMacOS) {
    return const UnsupportedKeyboardAdapter('macOS adapter (Quartz events + Accessibility permission) is not built yet; use clipboard or file output.');
  }
  if (Platform.isLinux) {
    final session = Platform.environment['XDG_SESSION_TYPE'] ?? 'unknown';
    return UnsupportedKeyboardAdapter('Linux ($session) adapter is not built yet; use clipboard or file output.');
  }
  return const UnsupportedKeyboardAdapter('Keyboard output is not supported on this platform.');
}
