import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../services.dart';
import '../widgets/export_dialog.dart';
import '../widgets/scan_detail_panel.dart';
import '../widgets/scan_list_tile.dart';

/// Scans of one session with search, bulk select, dedupe and export.
class SessionDetailPage extends ConsumerStatefulWidget {
  const SessionDetailPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends ConsumerState<SessionDetailPage> {
  final _search = TextEditingController();
  final _selected = <String>{};
  var _newestFirst = true;
  late Stream<List<ScanRecord>> _stream;
  ScanSession? _session;

  @override
  void initState() {
    super.initState();
    _stream = _query();
    ref.read(servicesProvider).sessions.byId(widget.sessionId).then((s) => mounted ? setState(() => _session = s) : null);
  }

  Stream<List<ScanRecord>> _query() => ref.read(servicesProvider).scans.watch(ScanFilter(
    sessionId: widget.sessionId,
    text: _search.text.trim(),
    newestFirst: _newestFirst,
    limit: 100000,
  ));

  Future<void> _bulkDelete() async {
    final l = context.l10n;
    final ids = _selected.toList();
    final ok = await confirmAction(context, title: l.deleteScansTitle, message: l.deleteScansBody(ids.length), confirmLabel: l.delete, destructive: true);
    if (!ok) return;
    final scans = ref.read(servicesProvider).scans;
    await scans.softDelete(ids);
    setState(_selected.clear);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.scansDeleted(ids.length)),
      action: SnackBarAction(label: l.undo, onPressed: () => scans.undoDelete(ids)),
    ));
  }

  Future<void> _dedupe() async {
    final l = context.l10n;
    final scans = ref.read(servicesProvider).scans;
    final groups = await scans.duplicateGroups(widget.sessionId);
    if (!mounted) return;
    final extra = [for (final g in groups.values) ...g.skip(1).map((s) => s.id)];
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.dedupeTitle),
        content: SizedBox(
          width: 420,
          child: groups.isEmpty
              ? Text(l.dedupeNone)
              : ListView(shrinkWrap: true, children: [
                  Text(l.dedupeBody(extra.length)),
                  for (final e in groups.entries) ListTile(dense: true, title: Text(e.key), trailing: Text('×${e.value.length}')),
                ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          if (groups.isNotEmpty) FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.removeDuplicates)),
        ],
      ),
    );
    if (ok != true) return;
    await scans.softDelete(extra);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.scansDeleted(extra.length)),
        action: SnackBarAction(label: l.undo, onPressed: () => scans.undoDelete(extra)),
      ));
    }
  }

  Future<void> _export(List<ScanRecord> all) async {
    final s = _session;
    if (s == null) return;
    final rows = _selected.isEmpty ? all : all.where((r) => _selected.contains(r.id)).toList();
    await exportScans(context, ref.read(servicesProvider).settings.current, s, _newestFirst ? rows.reversed.toList() : rows);
  }

  void _openDetail(ScanRecord scan) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SizedBox(height: MediaQuery.sizeOf(c).height * .7, child: ScanDetailPanel(scan: scan, onDeleted: () => Navigator.pop(c))),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<ScanRecord>>(
      stream: _stream,
      builder: (context, snap) {
        final scans = snap.data ?? const [];
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(Sb.m),
            child: Row(children: [
              IconButton(tooltip: l.back, onPressed: () => context.go('/sessions'), icon: const Icon(Icons.arrow_back)),
              Expanded(child: Text(_session?.name ?? '', style: context.text.titleLarge, overflow: TextOverflow.ellipsis)),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchScans),
                  onChanged: (_) => setState(() => _stream = _query()),
                ),
              ),
              IconButton(
                tooltip: _newestFirst ? l.sortNewest : l.sortOldest,
                onPressed: () => setState(() {
                  _newestFirst = !_newestFirst;
                  _stream = _query();
                }),
                icon: Icon(_newestFirst ? Icons.arrow_downward : Icons.arrow_upward),
              ),
              IconButton(tooltip: l.dedupeTitle, onPressed: _dedupe, icon: const Icon(Icons.filter_alt_off_outlined)),
              if (_selected.isNotEmpty)
                IconButton(tooltip: l.delete, onPressed: _bulkDelete, icon: const Icon(Icons.delete_outline)),
              FilledButton.icon(
                onPressed: () => _export(scans),
                icon: const Icon(Icons.file_download_outlined),
                label: Text(_selected.isEmpty ? l.export : l.exportSelected(_selected.length)),
              ),
            ]),
          ),
          if (scans.isNotEmpty)
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: _selected.length == scans.length,
              title: Text(l.selectAll),
              onChanged: (v) => setState(() => v! ? _selected.addAll(scans.map((s) => s.id)) : _selected.clear()),
            ),
          const Divider(height: 1),
          Expanded(
            child: scans.isEmpty
                ? EmptyState(icon: Icons.qr_code_2, title: l.noScansTitle, message: l.noScansDesktopHint)
                : ListView.builder(
                    itemCount: scans.length,
                    itemBuilder: (_, i) => ScanListTile(
                      scan: scans[i],
                      onTap: () => _openDetail(scans[i]),
                      leading: Checkbox(
                        value: _selected.contains(scans[i].id),
                        onChanged: (v) => setState(() => v! ? _selected.add(scans[i].id) : _selected.remove(scans[i].id)),
                      ),
                    ),
                  ),
          ),
        ]);
      },
    );
  }
}
