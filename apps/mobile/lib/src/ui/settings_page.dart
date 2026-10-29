import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../services.dart';
import '../settings/mobile_settings.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final s = ref.watch(settingsProvider).value ?? services.settings.current;
    Future<void> set(MobileSettings Function(MobileSettings) f) => services.settings.update(f);
    Future<void> rules(ScanRules Function(ScanRules) f) => set((x) => x.copyWith(rules: f(x.rules)));
    ScanRules copyRules(ScanRules r, {Set<Symbology>? formats, String? pattern, int? min, int? max, String? prefix, String? suffix, DuplicatePolicy? dup}) =>
        ScanRules(
          allowedFormats: formats ?? r.allowedFormats,
          pattern: pattern ?? r.pattern,
          minLength: min ?? r.minLength,
          maxLength: max ?? r.maxLength,
          requiredPrefix: prefix ?? r.requiredPrefix,
          requiredSuffix: suffix ?? r.requiredSuffix,
          duplicatePolicy: dup ?? r.duplicatePolicy,
        );
    Widget text(String label, String value, ValueChanged<String> save, {TextInputType? type}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sb.m, vertical: Sb.s),
      child: TextFormField(
        key: ValueKey('$label=$value'),
        initialValue: value,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, helperText: l.pressEnterToSave),
        onFieldSubmitted: (v) => save(v.trim()),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: ListView(padding: const EdgeInsets.only(bottom: Sb.xl), children: [
        _Header(l.settingsGeneral),
        text(l.deviceName, s.deviceName, (v) => v.isEmpty ? null : set((x) => x.copyWith(deviceName: v))),
        ListTile(
          title: Text(l.defaultScanMode),
          trailing: SegmentedButton<ScanMode>(
            segments: [ButtonSegment(value: ScanMode.single, label: Text(l.modeSingle)), ButtonSegment(value: ScanMode.continuous, label: Text(l.modeContinuous))],
            selected: {s.scanMode},
            onSelectionChanged: (v) => set((x) => x.copyWith(scanMode: v.first)),
          ),
        ),
        SwitchListTile(title: Text(l.haptics), value: s.haptics, onChanged: (v) => set((x) => x.copyWith(haptics: v))),
        SwitchListTile(title: Text(l.sound), value: s.sound, onChanged: (v) => set((x) => x.copyWith(sound: v))),
        ListTile(
          title: Text(l.theme),
          trailing: DropdownButton<ThemeChoice>(
            value: s.theme,
            onChanged: (v) => set((x) => x.copyWith(theme: v)),
            items: [
              DropdownMenuItem(value: ThemeChoice.system, child: Text(l.themeSystem)),
              DropdownMenuItem(value: ThemeChoice.light, child: Text(l.themeLight)),
              DropdownMenuItem(value: ThemeChoice.dark, child: Text(l.themeDark)),
            ],
          ),
        ),
        _Header(l.settingsScanning),
        text(l.defaultQuantity, s.defaultQuantity, (v) => RegExp(r'^\d+(\.\d+)?$').hasMatch(v) ? set((x) => x.copyWith(defaultQuantity: v)) : null, type: TextInputType.number),
        SwitchListTile(title: Text(l.askQuantity), value: s.askQuantity, onChanged: (v) => set((x) => x.copyWith(askQuantity: v))),
        ListTile(
          title: Text(l.duplicates),
          trailing: DropdownButton<DuplicatePolicy>(
            value: s.rules.duplicatePolicy,
            onChanged: (v) => rules((r) => copyRules(r, dup: v)),
            items: [
              DropdownMenuItem(value: DuplicatePolicy.allow, child: Text(l.dupAllow)),
              DropdownMenuItem(value: DuplicatePolicy.warn, child: Text(l.dupWarn)),
              DropdownMenuItem(value: DuplicatePolicy.block, child: Text(l.dupBlock)),
            ],
          ),
        ),
        ListTile(title: Text(l.formats), subtitle: Text(s.rules.allowedFormats.isEmpty ? l.allFormats : s.rules.allowedFormats.map((f) => f.name).join(', '))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sb.m),
          child: Wrap(spacing: Sb.xs, runSpacing: Sb.xs, children: [
            for (final f in Symbology.values.where((f) => f != Symbology.unknown))
              FilterChip(
                label: Text(f.name),
                selected: s.rules.allowedFormats.contains(f),
                onSelected: (on) => rules((r) => ScanRules.fromJson({
                  ...r.toJson(),
                  'allowedFormats': (on ? {...r.allowedFormats, f} : ({...r.allowedFormats}..remove(f))).map((e) => e.name).toList(),
                })),
              ),
          ]),
        ),
        _Header(l.validation),
        text(l.pattern, s.rules.pattern ?? '', (v) => rules((r) => ScanRules.fromJson({...r.toJson(), 'pattern': v}))),
        text(l.minLength, '${s.rules.minLength ?? ''}', (v) => rules((r) => ScanRules.fromJson({...r.toJson(), 'minLength': int.tryParse(v)})), type: TextInputType.number),
        text(l.maxLength, '${s.rules.maxLength ?? ''}', (v) => rules((r) => ScanRules.fromJson({...r.toJson(), 'maxLength': int.tryParse(v)})), type: TextInputType.number),
        text(l.requiredPrefix, s.rules.requiredPrefix ?? '', (v) => rules((r) => ScanRules.fromJson({...r.toJson(), 'requiredPrefix': v}))),
        text(l.requiredSuffix, s.rules.requiredSuffix ?? '', (v) => rules((r) => ScanRules.fromJson({...r.toJson(), 'requiredSuffix': v}))),
        text(l.hardwareDebounce, '${s.hardwareDebounceMs}', (v) => set((x) => x.copyWith(hardwareDebounceMs: (int.tryParse(v) ?? 300).clamp(0, 5000))), type: TextInputType.number),
        _Header(l.template),
        StreamBuilder<List<OutputTemplate>>(
          stream: services.templates.watchAll(),
          builder: (context, snap) {
            final list = snap.data ?? const [];
            return ListTile(
              title: Text(l.outputTemplate),
              subtitle: Text(list.isEmpty ? l.templatesFromComputer : l.templateOverrideHint),
              trailing: DropdownButton<String?>(
                value: list.any((t) => t.id == s.templateOverrideId) ? s.templateOverrideId : null,
                onChanged: (v) => set((x) => x.copyWith(templateOverrideId: () => v)),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l.computerDefault)),
                  for (final t in list) DropdownMenuItem<String?>(value: t.id, child: Text(t.name)),
                ],
              ),
            );
          },
        ),
        ListTile(title: Text(l.refreshTemplates), leading: const Icon(Icons.refresh), onTap: services.sync.refreshTemplates),
        _Header(l.privacy),
        Padding(padding: const EdgeInsets.symmetric(horizontal: Sb.m), child: Text(l.privacyMobile)),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Sb.m, Sb.l, Sb.m, Sb.xs),
    child: Text(text, style: context.text.titleSmall?.copyWith(color: context.colors.primary)),
  );
}
