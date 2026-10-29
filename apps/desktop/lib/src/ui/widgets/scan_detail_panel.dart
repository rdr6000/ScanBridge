import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../services.dart';

/// Details and actions for one scan: copy, preview, resend, edit, delete.
class ScanDetailPanel extends ConsumerWidget {
  const ScanDetailPanel({super.key, required this.scan, this.onDeleted});
  final ScanRecord scan;
  final VoidCallback? onDeleted;

  Future<void> _resend(BuildContext context, WidgetRef ref, {bool confirmed = false}) async {
    final l = context.l10n;
    final ok = await confirmAction(context, title: l.resendTitle, message: l.resendWarning, confirmLabel: l.resend);
    if (ok) await ref.read(servicesProvider).output.run(scan.id, confirmed: confirmed);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final value = await promptText(context, title: l.editValue, initial: scan.rawValue, label: l.value);
    if (value == null || value.isEmpty || !context.mounted) return;
    final qty = await promptText(context, title: l.editQuantity, initial: scan.quantity, label: l.quantity);
    if (qty != null && !RegExp(r'^-?\d+(\.\d+)?$').hasMatch(qty)) return;
    await ref.read(servicesProvider).scans.edit(scan.id, value: value, quantity: qty);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final scans = ref.read(servicesProvider).scans;
    await scans.softDelete([scan.id]);
    onDeleted?.call();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.l10n.scanDeleted),
      action: SnackBarAction(label: context.l10n.undo, onPressed: () => scans.undoDelete([scan.id])),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final needsConfirm = scan.outputStatus == OutputStatus.paused && (scan.outputError ?? '').startsWith('Needs confirmation');
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(k, style: context.text.labelMedium)),
        Expanded(child: SelectableText(v)),
      ]),
    );
    return ListView(padding: const EdgeInsets.all(Sb.m), children: [
      SelectableText(scan.value, style: context.text.headlineSmall?.copyWith(fontFamily: 'monospace')),
      const SizedBox(height: Sb.s),
      ScanStatusChips(scan),
      if (scan.outputError != null) ...[
        const SizedBox(height: Sb.s),
        Text(scan.outputError!, style: TextStyle(color: context.statusColors.error)),
      ],
      const Divider(height: Sb.l),
      row(l.symbology, scan.symbology.name),
      row(l.quantity, scan.quantity),
      row(l.capturedAt, formatLocal(context, scan.capturedAt)),
      if (scan.receivedAt != null) row(l.receivedAt, formatLocal(context, scan.receivedAt!)),
      row(l.source, scan.source.name),
      row(l.device, scan.deviceId),
      if (scan.templateId != null) row(l.template, '${scan.templateId} v${scan.templateVersion}'),
      for (final e in scan.values.entries) row(e.key, e.value),
      const Divider(height: Sb.l),
      Wrap(spacing: Sb.s, runSpacing: Sb.s, children: [
        OutlinedButton.icon(
          onPressed: () => Clipboard.setData(ClipboardData(text: scan.value)),
          icon: const Icon(Icons.copy),
          label: Text(l.copy),
        ),
        OutlinedButton.icon(onPressed: () => showDryRun(context, ref, scan), icon: const Icon(Icons.preview), label: Text(l.preview)),
        if (needsConfirm)
          FilledButton.icon(onPressed: () => _resend(context, ref, confirmed: true), icon: const Icon(Icons.check), label: Text(l.confirmAndRun))
        else
          OutlinedButton.icon(onPressed: () => _resend(context, ref), icon: const Icon(Icons.replay), label: Text(l.resend)),
        OutlinedButton.icon(onPressed: () => _edit(context, ref), icon: const Icon(Icons.edit), label: Text(l.edit)),
        OutlinedButton.icon(onPressed: () => _delete(context, ref), icon: const Icon(Icons.delete_outline), label: Text(l.delete)),
      ]),
    ]);
  }
}

/// Dry run: exact keystrokes, file writes and warnings without executing.
Future<void> showDryRun(BuildContext context, WidgetRef ref, ScanRecord scan) async {
  final l = context.l10n;
  TemplateRunResult? result;
  String? error;
  try {
    result = await ref.read(servicesProvider).output.preview(scan);
  } on AppFailure catch (f) {
    error = f.message;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.dryRunTitle),
      content: SizedBox(width: 480, child: DryRunView(result: result, error: error)),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l.close))],
    ),
  );
}

class DryRunView extends StatelessWidget {
  const DryRunView({super.key, this.result, this.error});
  final TemplateRunResult? result;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = result;
    if (error != null || r == null) return Text(error ?? '', style: TextStyle(color: context.statusColors.error));
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (r.failure != null) Text(r.failure!.message, style: TextStyle(color: context.statusColors.error)),
      if (r.halted) Text(l.dryRunHalted, style: TextStyle(color: context.statusColors.warning)),
      for (final w in r.warnings) Text('⚠ $w', style: TextStyle(color: context.statusColors.warning)),
      if (r.actions.isEmpty && r.ok && !r.halted) Text(l.dryRunNoActions),
      Flexible(
        child: ListView(shrinkWrap: true, children: [
          for (final (i, a) in r.actions.indexed)
            ListTile(dense: true, leading: Text('${i + 1}'), title: Text(a.describe(), style: const TextStyle(fontFamily: 'monospace'))),
        ]),
      ),
    ]);
  }
}
