import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import 'component_fields.dart';

/// Edits one component: label, schema-driven fields, or raw JSON.
Future<TemplateComponent?> editComponent(BuildContext context, TemplateComponent c) =>
    showDialog<TemplateComponent>(context: context, builder: (_) => _ConfigDialog(component: c));

class _ConfigDialog extends StatefulWidget {
  const _ConfigDialog({required this.component});
  final TemplateComponent component;

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  late final _label = TextEditingController(text: widget.component.label);
  late final _fields = fieldsFor(widget.component.type);
  late final _text = {
    for (final f in _fields.where((f) => f.kind != FieldKind.boolean && f.kind != FieldKind.choice))
      f.key: TextEditingController(text: formatField(f, widget.component.config[f.key])),
  };
  late final _flags = {for (final f in _fields.where((f) => f.kind == FieldKind.boolean)) f.key: widget.component.config[f.key] == true};
  late final _choice = {
    for (final f in _fields.where((f) => f.kind == FieldKind.choice))
      f.key: f.choices.contains(widget.component.config[f.key]) ? widget.component.config[f.key] as String : f.choices.first,
  };
  late final _json = TextEditingController(text: const JsonEncoder.withIndent('  ').convert(widget.component.config));
  var _raw = false;
  String? _error;

  void _save() {
    Map<String, Object?> config;
    if (_raw) {
      try {
        final decoded = jsonDecode(_json.text);
        if (decoded is! Map) throw const FormatException('must be an object');
        config = decoded.cast<String, Object?>();
      } on FormatException catch (e) {
        setState(() => _error = e.message);
        return;
      }
    } else {
      config = {...widget.component.config};
      for (final f in _fields) {
        final v = switch (f.kind) {
          FieldKind.boolean => _flags[f.key],
          FieldKind.choice => _choice[f.key],
          _ => parseField(f, _text[f.key]!.text),
        };
        v == null ? config.remove(f.key) : config[f.key] = v;
      }
    }
    Navigator.pop(context, widget.component.copyWith(label: _label.text.trim(), config: config));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.component.typeId),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _label, decoration: InputDecoration(labelText: l.label)),
            const SizedBox(height: Sb.m),
            if (_raw)
              TextField(controller: _json, maxLines: 12, style: const TextStyle(fontFamily: 'monospace'), decoration: InputDecoration(errorText: _error))
            else
              for (final f in _fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sb.s),
                  child: switch (f.kind) {
                    FieldKind.boolean => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.key),
                      value: _flags[f.key]!,
                      onChanged: (v) => setState(() => _flags[f.key] = v),
                    ),
                    FieldKind.choice => DropdownButtonFormField<String>(
                      initialValue: _choice[f.key],
                      decoration: InputDecoration(labelText: f.key),
                      items: [for (final c in f.choices) DropdownMenuItem(value: c, child: Text(c))],
                      onChanged: (v) => setState(() => _choice[f.key] = v!),
                    ),
                    _ => TextField(
                      controller: _text[f.key],
                      decoration: InputDecoration(labelText: f.key, helperText: f.kind == FieldKind.list ? l.commaSeparated : null),
                    ),
                  },
                ),
            if (!_raw) Text(l.variablesHint, style: context.text.bodySmall),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => setState(() => _raw = !_raw), child: Text(_raw ? l.formView : l.jsonView)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _save, child: Text(l.apply)),
      ],
    );
  }
}
