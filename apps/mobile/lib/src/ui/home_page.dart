import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../services.dart';
import 'link_banner.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final settings = ref.watch(settingsProvider).value;
    final sessionId = settings?.activeSessionId;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(tooltip: l.navSessions, onPressed: () => context.push('/sessions'), icon: const Icon(Icons.folder_open_outlined)),
          IconButton(tooltip: l.navSettings, onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(Sb.m), children: [
        const LinkBanner(),
        const SizedBox(height: Sb.m),
        FutureBuilder<ScanSession?>(
          future: sessionId == null ? Future.value() : services.sessions.byId(sessionId),
          builder: (context, snap) => Card(
            child: ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(snap.data?.name ?? l.noActiveSession),
              subtitle: Text(l.activeSession),
              trailing: TextButton(onPressed: () => context.push('/sessions'), child: Text(l.change)),
            ),
          ),
        ),
        const SizedBox(height: Sb.m),
        SizedBox(
          height: 120,
          child: FilledButton.icon(
            onPressed: () => context.push('/scan'),
            icon: const Icon(Icons.qr_code_scanner, size: 40),
            label: Text(l.scanButton, style: context.text.headlineSmall?.copyWith(color: context.colors.onPrimary)),
          ),
        ),
        const SizedBox(height: Sb.s),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => context.push('/scan?single=1'), icon: const Icon(Icons.filter_1), label: Text(l.scanSingle))),
          const SizedBox(width: Sb.s),
          Expanded(child: OutlinedButton.icon(onPressed: () => context.push('/manual'), icon: const Icon(Icons.keyboard), label: Text(l.manualEntry))),
        ]),
        const SizedBox(height: Sb.s),
        OutlinedButton.icon(onPressed: () => context.push('/manual?hardware=1'), icon: const Icon(Icons.barcode_reader), label: Text(l.hardwareScanner)),
        const SizedBox(height: Sb.l),
        Text(l.recentScans, style: context.text.titleMedium),
        if (sessionId == null)
          EmptyState(icon: Icons.qr_code_2, title: l.noScansTitle, message: l.noScansMobileHint)
        else
          StreamBuilder<List<ScanRecord>>(
            stream: services.scans.watch(ScanFilter(sessionId: sessionId, limit: 10)),
            builder: (context, snap) {
              final scans = snap.data ?? const [];
              if (scans.isEmpty) return EmptyState(icon: Icons.qr_code_2, title: l.noScansTitle, message: l.noScansMobileHint);
              return Column(children: [
                for (final s in scans)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.value, style: const TextStyle(fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${formatLocal(context, s.capturedAt)} · ${l.quantityShort} ${s.quantity}'),
                    trailing: ScanStatusChips(s),
                  ),
              ]);
            },
          ),
      ]),
    );
  }
}
