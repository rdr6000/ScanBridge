import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../services.dart';
import '../widgets/export_dialog.dart';

class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> {
  final _search = TextEditingController();
  var _archived = false;
  var _sort = SessionSort.updatedDesc;
  final _selected = <String>{};
  late Stream<List<ScanSession>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _query();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GoRouterState.of(context).uri.queryParameters['new'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _create());
    }
  }

  Stream<List<ScanSession>> _query() =>
      ref.read(servicesProvider).sessions.watch(search: _search.text.trim(), archived: _archived, sort: _sort);

  void _refresh() => setState(() => _stream = _query());

  Future<void> _create() async {
    final name = await promptText(context, title: context.l10n.newSession, label: context.l10n.name);
    if (name == null || name.isEmpty) return;
    final s = await ref.read(servicesProvider).sessions.create(name);
    if (mounted) context.go('/sessions/${s.id}');
  }

  Future<void> _rename(ScanSession s) async {
    final name = await promptText(context, title: context.l10n.rename, initial: s.name, label: context.l10n.name);
    if (name != null && name.isNotEmpty) await ref.read(servicesProvider).sessions.update(s.id, name: name);
  }

  Future<void> _delete(ScanSession s) async {
    final l = context.l10n;
    final ok = await confirmAction(context, title: l.deleteSessionTitle, message: l.deleteSessionBody(s.name, s.scanCount), confirmLabel: l.delete, destructive: true);
    if (ok) await ref.read(servicesProvider).sessions.delete(s.id);
  }

  Future<void> _export(ScanSession s) async {
    final services = ref.read(servicesProvider);
    final scans = await services.scans.forSession(s.id);
    if (mounted) await exportScans(context, services.settings.current, s, scans);
  }

  Future<void> _merge(List<ScanSession> all) async {
    final l = context.l10n;
    final picked = all.where((s) => _selected.contains(s.id)).toList();
    if (picked.length < 2) return;
    final target = picked.first;
    final ok = await confirmAction(context, title: l.mergeSessions, message: l.mergeSessionsBody(picked.length, target.name), confirmLabel: l.merge);
    if (!ok) return;
    await ref.read(servicesProvider).sessions.merge(target.id, picked.skip(1).map((s) => s.id));
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<ScanSession>>(
      stream: _stream,
      builder: (context, snap) {
        final sessions = snap.data ?? const [];
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(Sb.m),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchSessions),
                  onChanged: (_) => _refresh(),
                ),
              ),
              const SizedBox(width: Sb.s),
              DropdownButton<SessionSort>(
                value: _sort,
                onChanged: (v) {
                  _sort = v!;
                  _refresh();
                },
                items: [
                  DropdownMenuItem(value: SessionSort.updatedDesc, child: Text(l.sortUpdated)),
                  DropdownMenuItem(value: SessionSort.createdDesc, child: Text(l.sortNewest)),
                  DropdownMenuItem(value: SessionSort.createdAsc, child: Text(l.sortOldest)),
                  DropdownMenuItem(value: SessionSort.name, child: Text(l.sortName)),
                ],
              ),
              const SizedBox(width: Sb.s),
              FilterChip(label: Text(l.archived), selected: _archived, onSelected: (v) {
                _archived = v;
                _selected.clear();
                _refresh();
              }),
              const SizedBox(width: Sb.s),
              if (_selected.length > 1) OutlinedButton(onPressed: () => _merge(sessions), child: Text(l.merge)),
              const SizedBox(width: Sb.s),
              FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: Text(l.newSession)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: sessions.isEmpty
                ? EmptyState(icon: Icons.folder_open, title: l.noSessionsTitle, message: l.noSessionsHint)
                : ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (_, i) {
                      final s = sessions[i];
                      return ListTile(
                        leading: Checkbox(
                          value: _selected.contains(s.id),
                          onChanged: (v) => setState(() => v! ? _selected.add(s.id) : _selected.remove(s.id)),
                        ),
                        title: Text(s.name),
                        subtitle: Text('${l.scansCount(s.scanCount)} · ${formatLocal(context, s.updatedAt)}'),
                        onTap: () => context.go('/sessions/${s.id}'),
                        trailing: PopupMenuButton<String>(
                          tooltip: l.moreActions,
                          onSelected: (a) => switch (a) {
                            'rename' => _rename(s),
                            'export' => _export(s),
                            'archive' => ref.read(servicesProvider).sessions.setArchived(s.id, !s.isArchived),
                            _ => _delete(s),
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'rename', child: Text(l.rename)),
                            PopupMenuItem(value: 'export', child: Text(l.export)),
                            PopupMenuItem(value: 'archive', child: Text(s.isArchived ? l.restore : l.archive)),
                            PopupMenuItem(value: 'delete', child: Text(l.delete)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}
