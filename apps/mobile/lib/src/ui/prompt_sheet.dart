import 'package:flutter/material.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

/// Collects template prompt answers; validated by a dry run of the same engine.
Future<Map<String, String>?> showPromptSheet(BuildContext context, OutputTemplate template, String barcode) =>
    showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PromptSheet(template: template, barcode: barcode),
    );

class _PromptSheet extends StatefulWidget {
  const _PromptSheet({required this.template, required this.barcode});
  final OutputTemplate template;
  final String barcode;

  @override
  State<_PromptSheet> createState() => _PromptSheetState();
}

class _PromptSheetState extends State<_PromptSheet> {
  late final _values = <String, String>{
    for (final p in widget.template.prompts) p.id: p.type == ComponentType.confirm ? 'yes' : '${p.config['default'] ?? ''}',
  };
  String? _error;

  Future<void> _submit() async {
    final result = await const TemplateEngine().run(
      widget.template,
      ExecutionContext(
        barcode: widget.barcode,
        quantity: '1',
        capturedAt: nowUtc(),
        sessionName: '',
        deviceName: '',
        now: nowUtc(),
        values: _values,
      ),
    );
    if (!mounted) return;
    if (result.failure != null) return setState(() => _error = result.failure!.message);
    Navigator.pop(context, Map.of(_values));
  }

  Widget _field(TemplateComponent p) {
    final options = (p.config['options'] as List? ?? const []).map((e) => '$e').toList();
    switch (p.type) {
      case ComponentType.selectOption when options.isNotEmpty:
        final multi = p.config['multi'] == true;
        final picked = _values[p.id]!.split('|').where((e) => e.isNotEmpty).toSet();
        return Wrap(spacing: Sb.s, children: [
          for (final o in options)
            FilterChip(
              label: Text(o),
              selected: picked.contains(o),
              onSelected: (on) => setState(() {
                final next = multi ? ({...picked}..removeWhere((e) => e == o)) : <String>{};
                if (on) next.add(o);
                _values[p.id] = next.join('|');
              }),
            ),
        ]);
      case ComponentType.confirm:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(p.displayLabel),
          value: _values[p.id] == 'yes',
          onChanged: (v) => setState(() => _values[p.id] = v ? 'yes' : 'no'),
        );
      default:
        return TextFormField(
          initialValue: _values[p.id],
          autofocus: p == widget.template.prompts.first,
          keyboardType: p.type == ComponentType.number ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
          decoration: InputDecoration(labelText: p.displayLabel),
          onChanged: (v) => _values[p.id] = v.trim(),
          onFieldSubmitted: (_) => _submit(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(Sb.m, Sb.m, Sb.m, MediaQuery.viewInsetsOf(context).bottom + Sb.m),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.barcode, style: context.text.titleLarge?.copyWith(fontFamily: 'monospace')),
        Text(widget.template.name, style: context.text.bodySmall),
        const SizedBox(height: Sb.m),
        for (final p in widget.template.prompts) ...[
          if (p.type == ComponentType.selectOption) Text(p.displayLabel, style: context.text.labelLarge),
          _field(p),
          const SizedBox(height: Sb.m),
        ],
        if (_error != null) Text(_error!, style: TextStyle(color: context.statusColors.error)),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel))),
          const SizedBox(width: Sb.m),
          Expanded(child: FilledButton(onPressed: _submit, child: Text(l.saveScan))),
        ]),
      ]),
    );
  }
}
