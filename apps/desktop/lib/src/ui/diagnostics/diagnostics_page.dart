import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../host/host_state.dart';
import '../../services.dart';

/// Capabilities, network facts, firewall guidance and a redacted report.
class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});

  Map<String, Object?> _capabilities(DesktopServices s, HostState h) => {
    'os': Platform.operatingSystem,
    'osVersion': Platform.operatingSystemVersion,
    'desktopSession': Platform.environment['XDG_SESSION_TYPE'],
    'keyboardInjection': s.keyboard.capability.level.name,
    'keyboardReason': s.keyboard.capability.reason,
    'clipboardOutput': 'available',
    'fileOutput': 'available',
    'lanServer': h.running ? 'running' : h.status.name,
    'systemTray': 'not_implemented',
    'discovery': 'not_implemented (QR + manual IP)',
  };

  /// Redacted: no barcode values, tokens, secrets or device ids.
  String _report(DesktopServices s, HostState h) => const JsonEncoder.withIndent('  ').convert({
    'generatedAt': nowUtc().toIso8601String(),
    'protocolVersion': ProtocolLimits.version,
    'capabilities': _capabilities(s, h),
    'server': {'status': h.status.name, 'port': h.port, 'lanMode': h.lanMode, 'addresses': h.addresses, 'connectedDevices': h.clients.length},
    'recentErrors': h.recentErrors.take(20).toList(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final host = ref.watch(hostStateProvider).value ?? const HostState();
    final caps = _capabilities(services, host);
    return ListView(padding: const EdgeInsets.all(Sb.l), children: [
      Row(children: [
        Expanded(child: Text(l.navDiagnostics, style: context.text.headlineSmall)),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _report(services, host)));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.diagnosticsCopied)));
          },
          icon: const Icon(Icons.copy),
          label: Text(l.copyDiagnostics),
        ),
      ]),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.capabilities,
        child: Column(children: [
          for (final e in caps.entries)
            ListTile(dense: true, title: Text(e.key), subtitle: Text('${e.value ?? '-'}')),
        ]),
      ),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.firewallTitle,
        child: Text(switch (Platform.operatingSystem) {
          'windows' => l.firewallWindows(host.port == 0 ? ProtocolLimits.defaultPort : host.port),
          'macos' => l.firewallMac,
          _ => l.firewallLinux(host.port == 0 ? ProtocolLimits.defaultPort : host.port),
        }),
      ),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.recentErrors,
        child: host.recentErrors.isEmpty
            ? Text(l.noErrors)
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final e in host.recentErrors) SelectableText(e)]),
      ),
      const SizedBox(height: Sb.m),
      SectionCard(
        title: l.auditLog,
        child: StreamBuilder<List<AuditEvent>>(
          stream: services.audit.watchRecent(limit: 50),
          builder: (context, snap) => Column(children: [
            for (final e in snap.data ?? const <AuditEvent>[])
              ListTile(dense: true, title: Text('${e.category}.${e.action}'), subtitle: Text('${formatLocal(context, e.timestamp)} ${e.details}')),
          ]),
        ),
      ),
    ]);
  }
}
