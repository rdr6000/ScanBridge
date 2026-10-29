import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../services.dart';
import '../widgets/scan_detail_panel.dart';
import 'component_config_dialog.dart';

/// Ordered component builder with undo/redo, lint, dry run and versioned save.
class TemplateEditorPage extends ConsumerStatefulWidget {
  const TemplateEditorPage({super.key, required this.templateId});
  final String templateId;

  @override
  ConsumerState<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends ConsumerState<TemplateEditorPage> {
  OutputTemplate? _t;
  final _undo = <OutputTemplate>[];
  final _redo = <OutputTemplate>[];
  final _sample = TextEditingController(text: '000123456789');
  final _answers = <String, TextEditingController>{};
  TemplateRunResult? _preview;
  var _dirty = false;

  @override
  void initState() {
    super.initState();
    ref.read(servicesProvider).templates.get(widget.templateId).then((t) {
      final now = nowUtc();
      if (mounted) {
        setState(() => _t = t ?? OutputTemplate(id: newId(), name: 'New template', version: 0, components: const [], createdAt: now, updatedAt: now));
      }
    });
  }

  void _change(OutputTemplate next) => setState(() {
    _undo.add(_t!);
    _redo.clear();
    _t = next;
    _dirty = true;
    _preview = null;
  });

  void _setComponents(List<TemplateComponent> c) => _change(_t!.copyWith(components: c));

  void _undoStep() => setState(() {
    _redo.add(_t!);
    _t = _undo.removeLast();
    _dirty = true;
  });

  void _redoStep() => setState(() {
    _undo.add(_t!);
    _t = _redo.removeLast();
    _dirty = true;
  });

  Future<void> _save() async {
    final stored = await ref.read(servicesProvider).templates.save(_t!);
    setState(() {
      _t = stored;
      _dirty = false;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.templateSaved(stored.version))));
  }

  Future<void> _runPreview() async {
    final t = _t!;
    final scan = ScanRecord(
      id: 'preview',
      sessionId: 'preview',
      deviceId: 'preview',
      rawValue: _sample.text,
      capturedAt: nowUtc(),
      values: {for (final p in t.prompts) p.id: _answers[p.id]?.text ?? ''},
    );
    final services = ref.read(servicesProvider);
    final result = await const TemplateEngine().run(
      t,
      ExecutionContext.forScan(scan, sessionName: 'Preview', deviceName: 'Preview phone', counters: await services.settings.counters(), lookup: services.files),
    );
    setState(() => _preview = result);
  }

  Future<void> _add() async {
    final type = await showDialog<ComponentType>(
      context: context,
      builder: (c) => SimpleDialog(title: Text(c.l10n.addComponent), children: [
        for (final t in ComponentType.values)
          SimpleDialogOption(
            onPressed: t.available ? () => Navigator.pop(c, t) : null,
            child: Text(t.available ? t.id : '${t.id} — ${c.l10n.notAvailableYet}'),
          ),
      ]),
    );
    if (type == null) return;
    final created = TemplateComponent.create(type);
    if (!mounted) return;
    final configured = type == ComponentType.enter || type == ComponentType.tab ? created : await editComponent(context, created);
    if (configured != null) _setComponents([..._t!.components, configured]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = _t;
    if (t == null) return const Center(child: CircularProgressIndicator());
    final issues = const TemplateEngine().lint(t);
    final comps = t.components;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 3,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(Sb.m),
            child: Row(children: [
              IconButton(tooltip: l.back, onPressed: () => context.go('/templates'), icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: TextFormField(
                  key: ValueKey('name-${t.version}-${_undo.length}'),
                  initialValue: t.name,
                  decoration: InputDecoration(labelText: l.name),
                  onFieldSubmitted: (v) => v.trim().isEmpty ? null : _change(t.copyWith(name: v.trim())),
                ),
              ),
              const SizedBox(width: Sb.s),
              Text('v${t.version}${_dirty ? ' *' : ''}'),
              IconButton(tooltip: l.undo, onPressed: _undo.isEmpty ? null : _undoStep, icon: const Icon(Icons.undo)),
              IconButton(tooltip: l.redo, onPressed: _redo.isEmpty ? null : _redoStep, icon: const Icon(Icons.redo)),
              OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: Text(l.addComponent)),
              const SizedBox(width: Sb.s),
              FilledButton.icon(onPressed: _dirty ? _save : null, icon: const Icon(Icons.save), label: Text(l.save)),
            ]),
          ),
          for (final i in issues)
            ListTile(dense: true, leading: Icon(Icons.warning_amber, color: context.statusColors.warning), title: Text(i)),
          const Divider(height: 1),
          Expanded(
            child: comps.isEmpty
                ? EmptyState(icon: Icons.account_tree_outlined, title: l.noComponentsTitle, message: l.noComponentsHint)
                : ReorderableListView.builder(
                    itemCount: comps.length,
                    onReorderItem: (from, to) {
                      final list = [...comps];
                      list.insert(to, list.removeAt(from));
                      _setComponents(list);
                    },
                    itemBuilder: (_, i) => _ComponentTile(
                      key: ValueKey(comps[i].id),
                      index: i,
                      component: comps[i],
                      onChanged: (c) => _setComponents([...comps]..[i] = c),
                      onDelete: () => _setComponents([...comps]..removeAt(i)),
                      onDuplicate: () => _setComponents([...comps]..insert(i + 1, comps[i].copyWith(id: newId().substring(0, 8)))),
                    ),
                  ),
          ),
        ]),
      ),
      const VerticalDivider(width: 1),
      SizedBox(
        width: 380,
        child: ListView(padding: const EdgeInsets.all(Sb.m), children: [
          Text(l.dryRunTitle, style: context.text.titleMedium),
          const SizedBox(height: Sb.s),
          TextField(controller: _sample, decoration: InputDecoration(labelText: l.sampleBarcode)),
          for (final p in t.prompts)
            Padding(
              padding: const EdgeInsets.only(top: Sb.s),
              child: TextField(
                controller: _answers.putIfAbsent(p.id, () => TextEditingController(text: '${p.config['default'] ?? (p.type == ComponentType.confirm ? 'yes' : '')}')),
                decoration: InputDecoration(labelText: p.displayLabel),
              ),
            ),
          const SizedBox(height: Sb.s),
          FilledButton.tonalIcon(onPressed: _runPreview, icon: const Icon(Icons.play_arrow), label: Text(l.runPreview)),
          const SizedBox(height: Sb.m),
          if (_preview != null) DryRunView(result: _preview),
        ]),
      ),
    ]);
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({super.key, required this.index, required this.component, required this.onChanged, required this.onDelete, required this.onDuplicate});
  final int index;
  final TemplateComponent component;
  final ValueChanged<TemplateComponent> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = component;
    final summary = c.config.entries.map((e) => '${e.key}=${e.value}').join(', ');
    return ListTile(
      leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_indicator)),
      title: Text('${index + 1}. ${c.displayLabel}${c.label.isNotEmpty ? ' (${c.typeId})' : ''}',
          style: TextStyle(color: c.enabled ? null : context.colors.outline)),
      subtitle: summary.isEmpty ? null : Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: c.isKnown ? () async => editComponent(context, c).then((v) => v == null ? null : onChanged(v)) : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: l.skipOutput,
          isSelected: c.skipOutput,
          onPressed: () => onChanged(c.copyWith(skipOutput: !c.skipOutput)),
          icon: const Icon(Icons.visibility_outlined),
          selectedIcon: const Icon(Icons.visibility_off_outlined),
        ),
        Switch(value: c.enabled, onChanged: c.isKnown ? (v) => onChanged(c.copyWith(enabled: v)) : null),
        IconButton(tooltip: l.duplicate, onPressed: onDuplicate, icon: const Icon(Icons.copy_all_outlined)),
        IconButton(tooltip: l.delete, onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
      ]),
    );
  }
}
