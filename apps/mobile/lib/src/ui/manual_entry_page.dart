import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../services.dart';
import 'capture_flow.dart';
import 'link_banner.dart';

/// Typed/pasted codes, or keyboard-wedge hardware scanners that end with Enter.
class ManualEntryPage extends ConsumerStatefulWidget {
  const ManualEntryPage({super.key, this.hardware = false});
  final bool hardware;

  @override
  ConsumerState<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends ConsumerState<ManualEntryPage> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  String? _last;
  DateTime _lastAt = DateTime(0);
  var _count = 0;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    // Hardware scanners may send CR/LF/Tab suffixes; the value itself is kept verbatim.
    final value = raw.replaceAll(RegExp(r'[\r\n\t]+$'), '');
    if (value.isEmpty) return;
    final now = DateTime.now();
    final debounce = Duration(milliseconds: ref.read(servicesProvider).settings.current.hardwareDebounceMs);
    if (widget.hardware && value == _last && now.difference(_lastAt) < debounce) return;
    _last = value;
    _lastAt = now;
    _input.clear();
    final saved = await submitCode(context, ref, value, Symbology.unknown, widget.hardware ? ScanSource.hardware : ScanSource.manual);
    if (saved) setState(() => _count++);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(widget.hardware ? l.hardwareScanner : l.manualEntry)),
      body: Padding(
        padding: const EdgeInsets.all(Sb.m),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const LinkBanner(compact: true),
          const SizedBox(height: Sb.m),
          Text(widget.hardware ? l.hardwareHint : l.manualHint),
          const SizedBox(height: Sb.m),
          TextField(
            controller: _input,
            focusNode: _focus,
            autofocus: true,
            keyboardType: widget.hardware ? TextInputType.none : TextInputType.text,
            textInputAction: TextInputAction.send,
            style: context.text.headlineSmall?.copyWith(fontFamily: 'monospace'),
            decoration: InputDecoration(labelText: l.value, suffixIcon: IconButton(tooltip: l.saveScan, onPressed: () => _submit(_input.text), icon: const Icon(Icons.send))),
            onSubmitted: _submit,
          ),
          const SizedBox(height: Sb.m),
          Text(l.scannedThisRun(_count), style: context.text.titleMedium),
        ]),
      ),
    );
  }
}
