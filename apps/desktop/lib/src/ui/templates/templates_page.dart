import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../output/file_output.dart';
import '../../services.dart';

const _jsonGroup = XTypeGroup(label: 'JSON', extensions: ['json']);

class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key});

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final file = await openFile(acceptedTypeGroups: const [_jsonGroup]);
    if (file == null) return;
    final parsed = OutputTemplate.tryParse(await file.readAsString());
    if (!context.mounted) return;
    final t = parsed.valueOrNull;
    if (t == null) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l.importFailed),
          content: FailureBanner(parsed.failureOrNull!),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l.close))],
        ),
      );
      return;
    }
    final issues = const TemplateEngine().lint(t);
    final ok = await confirmAction(
      context,
      title: l.importPreviewTitle(t.name),
      message: [l.importPreviewBody(t.components.length), ...issues].join('\n'),
      confirmLabel: l.import,
    );
    // Imported templates get a fresh id so they never overwrite an existing one.
    if (ok) await ref.read(servicesProvider).templates.save(OutputTemplate.fromJson({...t.toJson(), 'id': newId()}));
  }

  Future<void> _export(BuildContext context, OutputTemplate t) async {
    final loc = await getSaveLocation(suggestedName: '${t.name}.json', acceptedTypeGroups: const [_jsonGroup]);
    if (loc == null) return;
    await FileOutput.writeAtomic(loc.path, t.toPrettyJson());
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.exportDone(loc.path))));
  }

  Future<void> _duplicate(WidgetRef ref, OutputTemplate t) =>
      ref.read(servicesProvider).templates.save(OutputTemplate.fromJson({...t.toJson(), 'id': newId(), 'name': '${t.name} copy'}));

  Future<void> _delete(BuildContext context, WidgetRef ref, OutputTemplate t) async {
    final l = context.l10n;
    if (await confirmAction(context, title: l.delete, message: l.deleteTemplateBody(t.name), confirmLabel: l.delete, destructive: true)) {
      await ref.read(servicesProvider).templates.delete(t.id);
    }
  }

  Future<void> _activate(WidgetRef ref, String id) async {
    final services = ref.read(servicesProvider);
    await services.settings.update((s) => s.copyWith(activeTemplateId: id));
    await services.host.pushTemplates();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final activeId = ref.watch(settingsProvider).value?.activeTemplateId;
    return StreamBuilder<List<OutputTemplate>>(
      stream: services.templates.watchAll(),
      builder: (context, snap) {
        final templates = snap.data ?? const [];
        return ListView(padding: const EdgeInsets.all(Sb.l), children: [
          Row(children: [
            Expanded(child: Text(l.navTemplates, style: context.text.headlineSmall)),
            OutlinedButton.icon(onPressed: () => _import(context, ref), icon: const Icon(Icons.file_upload_outlined), label: Text(l.import)),
            const SizedBox(width: Sb.s),
            FilledButton.icon(onPressed: () => context.go('/templates/new'), icon: const Icon(Icons.add), label: Text(l.newTemplate)),
          ]),
          const SizedBox(height: Sb.s),
          Text(l.templatesHint),
          const SizedBox(height: Sb.m),
          RadioGroup<String>(
            groupValue: activeId,
            onChanged: (v) => v == null ? null : _activate(ref, v),
            child: Column(children: [
              for (final t in templates)
                Card(
                  child: ListTile(
                    leading: Radio<String>(value: t.id),
                    title: Text(t.name),
                    subtitle: Text('${t.description.isEmpty ? '' : '${t.description} · '}v${t.version} · ${l.componentsCount(t.components.length)}'),
                    onTap: () => context.go('/templates/${t.id}'),
                    trailing: PopupMenuButton<String>(
                      tooltip: l.moreActions,
                      onSelected: (a) => switch (a) {
                        'export' => _export(context, t),
                        'duplicate' => _duplicate(ref, t),
                        _ => _delete(context, ref, t),
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'duplicate', child: Text(l.duplicate)),
                        PopupMenuItem(value: 'export', child: Text(l.export)),
                        if (t.id != activeId) PopupMenuItem(value: 'delete', child: Text(l.delete)),
                      ],
                    ),
                  ),
                ),
            ]),
          ),
        ]);
      },
    );
  }
}
