import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:win32/win32.dart';

import 'keyboard_adapter.dart';

/// SendInput-based typing. Text uses KEYEVENTF_UNICODE so layout does not matter.
class WindowsKeyboardAdapter implements KeyboardOutputAdapter {
  static const _named = <String, int>{
    'enter': 0x0D, 'tab': 0x09, 'escape': 0x1B, 'backspace': 0x08, 'delete': 0x2E, 'space': 0x20, //
    'up': 0x26, 'down': 0x28, 'left': 0x25, 'right': 0x27, 'home': 0x24, 'end': 0x23,
    'pageUp': 0x21, 'pageDown': 0x22, 'insert': 0x2D,
    'f1': 0x70, 'f2': 0x71, 'f3': 0x72, 'f4': 0x73, 'f5': 0x74, 'f6': 0x75,
    'f7': 0x76, 'f8': 0x77, 'f9': 0x78, 'f10': 0x79, 'f11': 0x7A, 'f12': 0x7B,
  };
  static const _extended = {0x2E, 0x26, 0x28, 0x25, 0x27, 0x24, 0x23, 0x21, 0x22, 0x2D};
  static const _ctrl = 0x11, _shift = 0x10, _alt = 0x12, _win = 0x5B;

  @override
  Capability get capability => const Capability(
    CapabilityLevel.available,
    'Windows SendInput. Apps running as administrator block input from non-elevated apps (UIPI).',
  );

  @override
  String? checkTarget() {
    final hwnd = GetForegroundWindow();
    if (hwnd.address == 0) return 'No foreground window (screen locked or secure desktop).';
    return using((arena) {
      final pid = arena<Uint32>();
      GetWindowThreadProcessId(hwnd, pid);
      final process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid.value).value;
      if (!process.isValid) return null;
      final token = arena<Pointer>();
      final opened = OpenProcessToken(process, TOKEN_QUERY, token).value;
      process.close();
      if (!opened) return 'The focused window appears to run with higher privileges; Windows blocks typing into it.';
      HANDLE(token.value).close();
      return null;
    });
  }

  @override
  Future<String?> typeText(String text, {Duration perKeyDelay = Duration.zero}) async {
    final blocked = checkTarget();
    if (blocked != null) return blocked;
    final units = text.replaceAll('\r\n', '\n').codeUnits;
    if (perKeyDelay == Duration.zero) return _send([for (final u in units) ..._unitEvents(u)]);
    for (final u in units) {
      final err = _send(_unitEvents(u));
      if (err != null) return err;
      await Future<void>.delayed(perKeyDelay);
    }
    return null;
  }

  @override
  Future<String?> pressKey(KeyChord chord) async {
    final blocked = checkTarget();
    if (blocked != null) return blocked;
    var vk = _named[chord.key];
    var shift = chord.shift;
    if (vk == null) {
      final scan = VkKeyScan(chord.key.codeUnitAt(0));
      if (scan == -1 || (scan & 0xFF) == 0xFF) return 'Key "${chord.key}" is not on the current keyboard layout.';
      vk = scan & 0xFF;
      shift = shift || (scan & 0x100) != 0;
    }
    final mods = [if (chord.ctrl) _ctrl, if (shift) _shift, if (chord.alt) _alt, if (chord.meta) _win];
    return _send([
      for (final m in mods) _Ev.vk(m, up: false),
      _Ev.vk(vk, up: false),
      _Ev.vk(vk, up: true),
      for (final m in mods.reversed) _Ev.vk(m, up: true),
    ]);
  }

  List<_Ev> _unitEvents(int unit) => switch (unit) {
    0x0A => [_Ev.vk(0x0D, up: false), _Ev.vk(0x0D, up: true)],
    0x09 => [_Ev.vk(0x09, up: false), _Ev.vk(0x09, up: true)],
    _ => [_Ev.unicode(unit, up: false), _Ev.unicode(unit, up: true)],
  };

  String? _send(List<_Ev> events) {
    if (events.isEmpty) return null;
    final p = calloc<INPUT>(events.length);
    try {
      for (var i = 0; i < events.length; i++) {
        final e = events[i];
        final input = (p + i).ref..type = INPUT_KEYBOARD;
        final ki = input.ki;
        var flags = e.up ? KEYEVENTF_KEYUP : 0;
        if (e.unicode) {
          ki.wVk = const VIRTUAL_KEY(0);
          ki.wScan = e.code;
          flags |= KEYEVENTF_UNICODE;
        } else {
          ki.wVk = VIRTUAL_KEY(e.code);
          if (_extended.contains(e.code)) flags |= KEYEVENTF_EXTENDEDKEY;
        }
        ki.dwFlags = KEYBD_EVENT_FLAGS(flags);
      }
      final result = SendInput(events.length, p, sizeOf<INPUT>());
      if (result.value != events.length) {
        return 'Windows accepted ${result.value}/${events.length} key events (error ${result.error}).';
      }
      return null;
    } finally {
      calloc.free(p);
    }
  }
}

class _Ev {
  const _Ev.vk(this.code, {required this.up}) : unicode = false;
  const _Ev.unicode(this.code, {required this.up}) : unicode = true;
  final int code;
  final bool up;
  final bool unicode;
}
