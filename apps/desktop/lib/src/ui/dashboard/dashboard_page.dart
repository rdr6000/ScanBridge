import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../host/host_state.dart';
import '../../services.dart';
import '../widgets/scan_list_tile.dart';
import 'pairing_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final host = ref.watch(hostStateProvider).value ?? const HostState();
    final settings = ref.watch(settingsProvider).value;
    return ListView(
      padding: const EdgeInsets.all(Sb.l),
      children: [
        Text(l.navDashboard, style: context.text.headlineSmall),
        const SizedBox(height: Sb.m),
        Wrap(spacing: Sb.m, runSpacing: Sb.m, children: [
          SizedBox(width: 420, child: _ServerCard(host: host, lanMode: settings?.lanMode ?? false)),
          const SizedBox(width: 420, child: PairingCard()),
          SizedBox(width: 420, child: _GettingStarted(host: host, lanMode: settings?.lanMode ?? false)),
        ]),
        const SizedBox(height: Sb.m),
        SectionCard(
          title: l.recentScans,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            StreamBuilder<int>(
              stream: services.scans.watchCount(output: OutputStatus.failed),
              builder: (_, s) => (s.data ?? 0) == 0
                  ? const SizedBox.shrink()
                  : ActionChip(
                      avatar: Icon(Icons.error_outline, color: context.statusColors.error),
                      label: Text(l.outputFailuresCount(s.data!)),
                      onPressed: () => context.go('/feed?failed=1'),
                    ),
            ),
            TextButton(onPressed: () => context.go('/feed'), child: Text(l.openFeed)),
          ]),
          child: StreamBuilder<List<ScanRecord>>(
            stream: services.scans.watch(const ScanFilter(limit: 8)),
            builder: (context, snap) {
              final scans = snap.data ?? const [];
              if (scans.isEmpty) {
                return EmptyState(icon: Icons.qr_code_2, title: l.noScansTitle, message: l.noScansDesktopHint);
              }
              return Column(children: [for (final s in scans) ScanListTile(scan: s)]);
            },
          ),
        ),
      ],
    );
  }
}

class _ServerCard extends ConsumerWidget {
  const _ServerCard({required this.host, required this.lanMode});
  final HostState host;
  final bool lanMode;

  Future<void> _toggleLan(BuildContext context, WidgetRef ref, bool enable) async {
    final l = context.l10n;
    if (enable && !await confirmAction(context, title: l.lanModeTitle, message: l.lanModeWarning, confirmLabel: l.enable)) return;
    final services = ref.read(servicesProvider);
    await services.settings.update((s) => s.copyWith(lanMode: enable));
    if (services.host.state.running) await services.host.restart();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final host = ref.read(servicesProvider).host;
    return SectionCard(
      title: l.serverTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.lanModeTitle),
          subtitle: Text(lanMode ? l.lanModeOnHint : l.lanModeOffHint),
          value: lanMode,
          onChanged: (v) => _toggleLan(context, ref, v),
        ),
        if (this.host.error != null) Text(this.host.error!, style: TextStyle(color: context.statusColors.error)),
        if (this.host.running)
          SelectableText(
            this.host.addresses.map((a) => '$a:${this.host.port}').join('\n'),
            style: context.text.titleMedium?.copyWith(fontFamily: 'monospace'),
          ),
        const SizedBox(height: Sb.s),
        this.host.running
            ? OutlinedButton.icon(onPressed: host.stop, icon: const Icon(Icons.stop), label: Text(l.stopServer))
            : FilledButton.icon(onPressed: host.start, icon: const Icon(Icons.play_arrow), label: Text(l.startServer)),
      ]),
    );
  }
}

class _GettingStarted extends ConsumerWidget {
  const _GettingStarted({required this.host, required this.lanMode});
  final HostState host;

  /// Saved preference, so the step stays checked while the server is stopped.
  final bool lanMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    Widget step(bool done, String text, [VoidCallback? onTap]) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? context.statusColors.success : null),
      title: Text(text),
      onTap: onTap,
    );
    return SectionCard(
      title: l.gettingStarted,
      child: StreamBuilder<List<Device>>(
        stream: services.devices.watchAll(),
        builder: (context, devices) => StreamBuilder<int>(
          stream: services.scans.watchCount(),
          builder: (context, count) => Column(children: [
            step(lanMode, l.stepLan),
            step(host.running, l.stepStart),
            step((devices.data ?? const []).any((d) => d.status == DeviceStatus.paired), l.stepPair, () => context.go('/devices')),
            step(false, l.stepKeyboard, () => context.go('/keyboard')),
            step((count.data ?? 0) > 0, l.stepScan, () => context.go('/feed')),
          ]),
        ),
      ),
    );
  }
}
