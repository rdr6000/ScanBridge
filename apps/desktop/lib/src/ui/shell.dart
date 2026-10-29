import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../host/host_state.dart';
import '../services.dart';

class _Dest {
  const _Dest(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String Function(SbLocalizations) label;
}

final _destinations = [
  _Dest('/', Icons.dashboard_outlined, (l) => l.navDashboard),
  _Dest('/feed', Icons.dynamic_feed_outlined, (l) => l.navFeed),
  _Dest('/sessions', Icons.folder_open_outlined, (l) => l.navSessions),
  _Dest('/devices', Icons.smartphone_outlined, (l) => l.navDevices),
  _Dest('/templates', Icons.account_tree_outlined, (l) => l.navTemplates),
  _Dest('/keyboard', Icons.keyboard_outlined, (l) => l.navKeyboardTest),
  _Dest('/settings', Icons.settings_outlined, (l) => l.navSettings),
  _Dest('/diagnostics', Icons.monitor_heart_outlined, (l) => l.navDiagnostics),
];

/// Navigation rail, persistent status bar, global shortcuts and dialogs.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _shown = <PendingPairing>{};
  StreamSubscription<String>? _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = ref.read(servicesProvider).output.alerts.listen((m) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    });
  }

  @override
  void dispose() {
    _alerts?.cancel();
    super.dispose();
  }

  int get _index {
    final i = _destinations.lastIndexWhere((d) => d.path == '/' ? widget.location == '/' : widget.location.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  Future<void> _toggleArmed() =>
      ref.read(servicesProvider).settings.update((s) => s.copyWith(keyboardArmed: !s.keyboardArmed));

  void _showApprovals(HostState state) {
    for (final p in state.pending.where((p) => !_shown.contains(p))) {
      _shown.add(p);
      final l = context.l10n;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: Text(l.pairApproveTitle),
          content: Text(l.pairApproveBody(p.deviceName, p.platform, p.address)),
          actions: [
            TextButton(onPressed: () => _decide(c, p, false), child: Text(l.decline)),
            FilledButton(onPressed: () => _decide(c, p, true), child: Text(l.approve)),
          ],
        ),
      );
    }
  }

  void _decide(BuildContext dialog, PendingPairing p, bool ok) {
    ref.read(servicesProvider).host.decide(p, ok);
    Navigator.pop(dialog);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(hostStateProvider, (_, next) => next.whenData(_showApprovals));
    final l = context.l10n;
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true): _toggleArmed,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => context.go('/feed?focus=1'),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => context.go('/sessions?new=1'),
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): () => context.go('/sessions'),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(children: [
            NavigationRail(
              extended: wide,
              selectedIndex: _index,
              labelType: wide ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              onDestinationSelected: (i) => context.go(_destinations[i].path),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: Sb.m),
                child: Icon(Icons.qr_code_scanner, size: 32, color: context.colors.primary),
              ),
              destinations: [
                for (final d in _destinations) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label(l))),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(children: [
                const _StatusBar(),
                const Divider(height: 1),
                Expanded(child: widget.child),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Always-visible server/connection state and the keyboard arm switch.
class _StatusBar extends ConsumerWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final host = ref.watch(hostStateProvider).value ?? const HostState();
    final settings = ref.watch(settingsProvider).value;
    final armed = settings?.keyboardArmed ?? false;
    final services = ref.read(servicesProvider);
    final (label, tone) = switch (host.status) {
      ServerStatus.running => (l.serverRunning(host.port), Tone.success),
      ServerStatus.starting => (l.serverStarting, Tone.info),
      ServerStatus.error => (l.serverError, Tone.error),
      ServerStatus.stopped => (l.serverStopped, Tone.neutral),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sb.m, vertical: Sb.s),
      child: Row(children: [
        StatusChip(label, tone, icon: Icons.dns_outlined),
        const SizedBox(width: Sb.s),
        StatusChip(l.devicesConnected(host.clients.length), host.clients.isEmpty ? Tone.neutral : Tone.info, icon: Icons.smartphone),
        if (host.lanMode) ...[const SizedBox(width: Sb.s), StatusChip(l.lanModeOn, Tone.warning, icon: Icons.lan_outlined)],
        const Spacer(),
        Tooltip(
          message: l.pauseShortcutHint,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: (armed ? context.statusColors.success : context.statusColors.warning).withValues(alpha: .18),
            ),
            onPressed: () => services.settings.update((s) => s.copyWith(keyboardArmed: !armed)),
            icon: Icon(armed ? Icons.keyboard : Icons.pause_circle_outline),
            label: Text(armed ? l.keyboardArmed : l.keyboardPaused),
          ),
        ),
      ]),
    );
  }
}
