import 'package:flutter/services.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

import 'keyboard_adapter.dart';

/// Explicit clipboard write and optional paste fallback that restores the
/// previous text clipboard. Non-text clipboard contents cannot be restored.
class ClipboardOutput {
  const ClipboardOutput(this.keyboard);
  final KeyboardOutputAdapter keyboard;

  Future<void> write(String text) => Clipboard.setData(ClipboardData(text: text));

  /// Copies [text], sends Ctrl+V, then restores the prior text clipboard.
  Future<String?> paste(String text) async {
    final previous = await Clipboard.getData(Clipboard.kTextPlain);
    await write(text);
    final err = await keyboard.pressKey(const KeyChord('v', ctrl: true));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (previous?.text != null) await write(previous!.text!);
    return err;
  }
}
