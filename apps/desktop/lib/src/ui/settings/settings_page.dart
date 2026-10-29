import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../host/host_settings.dart';
import '../../services.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final s = ref.watch(settingsProvider).value ?? services.settings.current;
    Future<void> set(HostSettings Function(HostSettings) f) => services.settings.update(f);

    Future<void> setNetwork(HostSettings Function(HostSettings) f) async {
      await set(f);
      if (services.host.state.running) await services.host.restart();
    }

    return ListView(padding: const EdgeInsets.all(Sb.l), children: [
      Text(l.navSettings, style: context.text.headlineSmall),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.settingsGeneral,
        child: Column(children: [
          _TextSetting(label: l.serverName, value: s.serverName, onSubmit: (v) => set((x) => x.copyWith(serverName: v))),
          SwitchListTile(title: Text(l.autoStartServer), value: s.autoStart, onChanged: (v) => set((x) => x.copyWith(autoStart: v))),
          ListTile(
            title: Text(l.theme),
            trailing: SegmentedButton<ThemePreference>(
              segments: [
                ButtonSegment(value: ThemePreference.system, label: Text(l.themeSystem)),
                ButtonSegment(value: ThemePreference.light, label: Text(l.themeLight)),
                ButtonSegment(value: ThemePreference.dark, label: Text(l.themeDark)),
              ],
              selected: {s.theme},
              onSelectionChanged: (v) => set((x) => x.copyWith(theme: v.first)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.settingsNetwork,
        child: Column(children: [
          _TextSetting(
            label: l.port,
            value: '${s.port}',
            onSubmit: (v) {
              final port = int.tryParse(v);
              if (port != null && port > 1024 && port < 65536) setNetwork((x) => x.copyWith(port: port));
            },
          ),
          SwitchListTile(title: Text(l.lanModeTitle), subtitle: Text(l.lanModeWarning), value: s.lanMode, onChanged: (v) => setNetwork((x) => x.copyWith(lanMode: v))),
        ]),
      ),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.settingsKeyboard,
        child: Column(children: [
          SwitchListTile(title: Text(l.keyboardArmed), subtitle: Text(l.pauseShortcutHint), value: s.keyboardArmed, onChanged: (v) => set((x) => x.copyWith(keyboardArmed: v))),
          _TextSetting(label: l.keyDelay, value: '${s.keyDelayMs}', onSubmit: (v) => set((x) => x.copyWith(keyDelayMs: (int.tryParse(v) ?? 0).clamp(0, 500)))),
          SwitchListTile(title: Text(l.clipboardFallback), subtitle: Text(l.clipboardFallbackHint), value: s.clipboardFallback, onChanged: (v) => set((x) => x.copyWith(clipboardFallback: v))),
          SwitchListTile(title: Text(l.confirmDestructive), subtitle: Text(l.confirmDestructiveHint), value: s.confirmDestructive, onChanged: (v) => set((x) => x.copyWith(confirmDestructive: v))),
        ]),
      ),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.settingsFiles,
        child: Column(children: [
          ListTile(
            title: Text(l.outputFolder),
            subtitle: SelectableText(s.outputDirectory),
            trailing: OutlinedButton(
              onPressed: () async {
                final dir = await getDirectoryPath();
                if (dir != null) await set((x) => x.copyWith(outputDirectory: dir));
              },
              child: Text(l.change),
            ),
          ),
          SwitchListTile(title: Text(l.csvBom), value: s.csvBom, onChanged: (v) => set((x) => x.copyWith(csvBom: v))),
          SwitchListTile(title: Text(l.csvFormulaGuard), subtitle: s.csvFormulaGuard ? null : Text(l.csvFormulaGuardOffWarning), value: s.csvFormulaGuard, onChanged: (v) => set((x) => x.copyWith(csvFormulaGuard: v))),
        ]),
      ),
      const SizedBox(height: Sb.m),
      const _DataSection(),
    ]);
  }
}

class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    return SectionCard(
      title: l.settingsData,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SelectableText('${l.dataLocation}: ${services.databaseFile.path}'),
        FutureBuilder<int>(
          future: services.db.sizeBytes(),
          builder: (_, s) => Text('${l.databaseSize}: ${((s.data ?? 0) / 1024).toStringAsFixed(1)} KB'),
        ),
        const SizedBox(height: Sb.s),
        OutlinedButton.icon(
          icon: const Icon(Icons.backup_outlined),
          label: Text(l.backupDatabase),
          onPressed: () async {
            final stamp = nowUtc().toIso8601String().replaceAll(RegExp('[:.]'), '-');
            final loc = await getSaveLocation(suggestedName: 'scanbridge-backup-$stamp.db');
            if (loc == null) return;
            await services.db.backupTo(File(loc.path));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.backupDone(loc.path))));
          },
        ),
        const SizedBox(height: Sb.s),
        Text(l.restoreHint, style: context.text.bodySmall),
      ]),
    );
  }
}

class _TextSetting extends StatelessWidget {
  const _TextSetting({required this.label, required this.value, required this.onSubmit});
  final String label;
  final String value;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Sb.m, vertical: Sb.s),
    child: TextFormField(
      key: ValueKey('$label=$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: label, helperText: context.l10n.pressEnterToSave),
      onFieldSubmitted: (v) => onSubmit(v.trim()),
    ),
  );
}
