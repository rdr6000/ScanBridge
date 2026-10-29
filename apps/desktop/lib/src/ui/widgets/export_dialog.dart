import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../host/host_settings.dart';
import '../../output/file_output.dart';

/// Asks for format/options, then a destination, then writes atomically.
Future<void> exportScans(BuildContext context, HostSettings settings, ScanSession session, List<ScanRecord> scans) async {
  final l = context.l10n;
  var format = ExportFormat.csv;
  var bom = settings.csvBom;
  var guard = settings.csvFormulaGuard;
  final go = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: Text(l.exportTitle(scans.length)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SegmentedButton<ExportFormat>(
            segments: [for (final f in ExportFormat.values) ButtonSegment(value: f, label: Text(f.extension.toUpperCase()))],
            selected: {format},
            onSelectionChanged: (v) => setState(() => format = v.first),
          ),
          if (format == ExportFormat.csv || format == ExportFormat.tsv) ...[
            CheckboxListTile(value: bom, onChanged: (v) => setState(() => bom = v!), title: Text(l.csvBom)),
            CheckboxListTile(value: guard, onChanged: (v) => setState(() => guard = v!), title: Text(l.csvFormulaGuard)),
            if (!guard) Text(l.csvFormulaGuardOffWarning, style: TextStyle(color: c.statusColors.warning)),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.export)),
        ],
      ),
    ),
  );
  if (go != true || !context.mounted) return;
  final safeName = session.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final location = await getSaveLocation(
    suggestedName: '$safeName.${format.extension}',
    acceptedTypeGroups: [XTypeGroup(label: format.extension.toUpperCase(), extensions: [format.extension])],
  );
  if (location == null || !context.mounted) return;
  final content = SessionExporter(csvOptions: CsvOptions(utf8Bom: bom, formulaGuard: guard)).export(format, session, scans);
  try {
    await FileOutput.writeAtomic(location.path, content);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.exportDone(location.path))));
  } on Object catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.exportFailed('$e'))));
    }
  }
}
