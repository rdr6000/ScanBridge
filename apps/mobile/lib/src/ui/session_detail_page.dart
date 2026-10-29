import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../services.dart';

/// Scans of a session: search, edit, delete with undo, resend and share.
class SessionDetailPage extends ConsumerStatefulWidget {
  const SessionDetailPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends ConsumerState<SessionDetailPage> {
  var _search = '';

  Future<void> _share(ExportFormat format) async {
    final services = ref.read(servicesProvider);
    final session = await services.sessions.byId(widget.sessionId);
    if (session == null) return;
    final scans = await services.scans.forSession(session.id);
    final dir = await getTemporaryDirectory();
    final name = session.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File(p.join(dir.path, '$name.${format.extension}'));
    await file.writeAsString(const SessionExporter().export(format, session, scans), flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: session.name));
  }

  /// Re-queues failed/rejected/local-only scans with their original ids.
  Future<void> _resendAll(List<ScanRecord> scans) async {
    final services = ref.read(servicesProvider);
    final todo = scans.where((s) => s.deliveryStatus != DeliveryStatus.received && s.deliveryStatus != DeliveryStatus.queued);
    for (final s in todo) {
      await services.outbox.enqueue(s.id);
    }
    await services.outbox.retryAll();
    services.sync.kick();
  }

  Future<void> _edit(ScanRecord s) async {
    final l = context.l10n;
    final qty = await promptText(context, title: l.editQuantity, initial: s.quantity, label: l.quantity);
    if (qty == null || !RegExp(r'^-?\d+(\.\d+)?$').hasMatch(qty)) return;
    await ref.read(servicesProvider).scans.edit(s.id, quantity: qty);
  }

  Future<void> _delete(ScanRecord s) async {
    final scans = ref.read(servicesProvider).scans;
    await scans.softDelete([s.id]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.l10n.scanDeleted),
      action: SnackBarAction(label: context.l10n.undo, onPressed: () => scans.undoDelete([s.id])),
    ));
  }

  /// Rejections are errors; otherwise the note follows the output status (paused = warning).
  Tone _noteTone(ScanRecord s) => s.deliveryStatus == DeliveryStatus.rejected ? Tone.error : s.outputStatus.tone;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    return StreamBuilder<List<ScanRecord>>(
      stream: services.scans.watch(ScanFilter(sessionId: widget.sessionId, text: _search, limit: 100000)),
      builder: (context, snap) {
        final scans = snap.data ?? const [];
        final unsent = scans.where((s) => s.deliveryStatus != DeliveryStatus.received && s.deliveryStatus != DeliveryStatus.queued).length;
        return Scaffold(
          appBar: AppBar(title: Text(l.sessionScans), actions: [
            if (unsent > 0) IconButton(tooltip: l.resendUnsent(unsent), onPressed: () => _resendAll(scans), icon: const Icon(Icons.sync)),
            PopupMenuButton<ExportFormat>(
              tooltip: l.export,
              icon: const Icon(Icons.share_outlined),
              onSelected: _share,
              itemBuilder: (_) => [for (final f in ExportFormat.values) PopupMenuItem(value: f, child: Text(f.extension.toUpperCase()))],
            ),
          ]),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.all(Sb.m),
              child: TextField(
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchScans),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            Expanded(
              child: scans.isEmpty
                  ? EmptyState(icon: Icons.qr_code_2, title: l.noScansTitle, message: l.noScansMobileHint)
                  : ListView.builder(
                      itemCount: scans.length,
                      itemBuilder: (_, i) {
                        final s = scans[i];
                        return Dismissible(
                          key: ValueKey(s.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: context.statusColors.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: Sb.m),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _delete(s),
                          child: ListTile(
                            title: Text(s.value, style: const TextStyle(fontFamily: 'monospace'), maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${formatLocal(context, s.capturedAt)} · ${l.quantityShort} ${s.quantity}'),
                              if (s.outputError != null)
                                Text(s.outputError!, style: TextStyle(color: context.statusColors.of(_noteTone(s)))),
                              const SizedBox(height: Sb.xs),
                              ScanStatusChips(s),
                            ]),
                            onTap: () => _edit(s),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        );
      },
    );
  }
}
