import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../output/keyboard_adapter.dart';
import '../../services.dart';

/// Lets the operator verify typing into this field or another focused app.
class KeyboardTestPage extends ConsumerStatefulWidget {
  const KeyboardTestPage({super.key});

  @override
  ConsumerState<KeyboardTestPage> createState() => _KeyboardTestPageState();
}

class _KeyboardTestPageState extends ConsumerState<KeyboardTestPage> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  final _sequence = TextEditingController(text: 'ScanBridge-000123 ✓');
  var _withEnter = true;
  var _countdown = 0;
  String? _result;

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    _sequence.dispose();
    super.dispose();
  }

  Future<void> _send({required bool otherApp}) async {
    final kb = ref.read(servicesProvider).keyboard;
    final delay = Duration(milliseconds: ref.read(servicesProvider).settings.current.keyDelayMs);
    if (otherApp) {
      for (_countdown = 5; _countdown > 0; _countdown--) {
        setState(() {});
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } else {
      _focus.requestFocus();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    var err = await kb.typeText(_sequence.text, perKeyDelay: delay);
    if (err == null && _withEnter) err = await kb.pressKey(KeyChord.enter);
    if (mounted) setState(() => _result = err ?? context.l10n.keyboardTestOk);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cap = ref.watch(servicesProvider).keyboard.capability;
    final tone = switch (cap.level) {
      CapabilityLevel.available => Tone.success,
      CapabilityLevel.limited || CapabilityLevel.permissionRequired => Tone.warning,
      CapabilityLevel.unavailable => Tone.error,
    };
    return ListView(padding: const EdgeInsets.all(Sb.l), children: [
      Text(l.navKeyboardTest, style: context.text.headlineSmall),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.keyboardCapability,
        trailing: StatusChip(cap.level.name, tone),
        child: Text(cap.reason),
      ),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.keyboardTestTitle,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _sequence, decoration: InputDecoration(labelText: l.testSequence)),
          CheckboxListTile(contentPadding: EdgeInsets.zero, value: _withEnter, onChanged: (v) => setState(() => _withEnter = v!), title: Text(l.appendEnter)),
          Text(l.sequencePreview(_sequence.text, _withEnter ? 'Enter' : '-'), style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(height: Sb.m),
          TextField(controller: _field, focusNode: _focus, maxLines: 3, decoration: InputDecoration(labelText: l.testTarget)),
          const SizedBox(height: Sb.m),
          Wrap(spacing: Sb.s, runSpacing: Sb.s, children: [
            FilledButton.icon(
              onPressed: cap.usable ? () => _send(otherApp: false) : null,
              icon: const Icon(Icons.keyboard),
              label: Text(l.sendTestHere),
            ),
            OutlinedButton.icon(
              onPressed: cap.usable && _countdown == 0 ? () => _send(otherApp: true) : null,
              icon: const Icon(Icons.timer_outlined),
              label: Text(_countdown > 0 ? l.switchWindowCountdown(_countdown) : l.sendTestOtherApp),
            ),
          ]),
          if (_result != null) ...[const SizedBox(height: Sb.m), Text(_result!)],
          const SizedBox(height: Sb.m),
          Text(l.keyboardLimitations, style: context.text.bodySmall),
        ]),
      ),
    ]);
  }
}
