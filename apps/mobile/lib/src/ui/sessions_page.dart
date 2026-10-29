import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../services.dart';

class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> {
  var _archived = false;
  var _search = '';

  Future<void> _activate(ScanSession s) async {
    await ref.read(servicesProvider).settings.update((x) => x.copyWith(activeSessionId: () => s.id));
    if (mounted) context.pop();
  }

  Future<void> _create() async {
    final l = context.l10n;
    final name = await promptText(context, title: l.newSession, label: l.name);
    if (name == null || name.isEmpty) return;
    final services = ref.read(servicesProvider);
    final s = await services.sessions.create(name, deviceId: services.link.deviceId);
    await _activate(s);
  }

  Future<void> _rename(ScanSession s) async {
    final services = ref.read(servicesProvider);
    final name = await promptText(context, title: context.l10n.rename, initial: s.name);
    if (name == null || name.isEmpty) return;
    await services.sessions.update(s.id, name: name);
    services.link.send(Envelope(type: MessageType.sessionUpdate, payload: SessionUpdatePayload(sessionId: s.id, name: name).toJson()));
  }

  Future<void> _delete(ScanSession s) async {
    final l = context.l10n;
    if (await confirmAction(context, title: l.deleteSessionTitle, message: l.deleteSessionBody(s.name, s.scanCount), confirmLabel: l.delete, destructive: true)) {
      await ref.read(servicesProvider).sessions.delete(s.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final activeId = ref.watch(settingsProvider).value?.activeSessionId;
    return Scaffold(
      appBar: AppBar(title: Text(l.navSessions), actions: [
        IconButton(
          tooltip: l.archived,
          isSelected: _archived,
          onPressed: () => setState(() => _archived = !_archived),
          icon: const Icon(Icons.inventory_2_outlined),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: Text(l.newSession)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(Sb.m),
          child: TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchSessions),
            onChanged: (v) => setState(() => _search = v.trim()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ScanSession>>(
            stream: services.sessions.watch(search: _search, archived: _archived),
            builder: (context, snap) {
              final list = snap.data ?? const [];
              if (list.isEmpty) return EmptyState(icon: Icons.folder_open, title: l.noSessionsTitle, message: l.noSessionsHint);
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final s = list[i];
                  return ListTile(
                    leading: Icon(s.id == activeId ? Icons.radio_button_checked : Icons.radio_button_off, color: s.id == activeId ? context.colors.primary : null),
                    title: Text(s.name),
                    subtitle: Text('${l.scansCount(s.scanCount)} · ${formatLocal(context, s.updatedAt)}'),
                    onTap: () => context.push('/sessions/${s.id}'),
                    trailing: PopupMenuButton<String>(
                      tooltip: l.moreActions,
                      onSelected: (a) => switch (a) {
                        'use' => _activate(s),
                        'rename' => _rename(s),
                        'archive' => services.sessions.setArchived(s.id, !s.isArchived),
                        _ => _delete(s),
                      },
                      itemBuilder: (_) => [
                        if (!s.isArchived) PopupMenuItem(value: 'use', child: Text(l.useSession)),
                        PopupMenuItem(value: 'rename', child: Text(l.rename)),
                        PopupMenuItem(value: 'archive', child: Text(s.isArchived ? l.restore : l.archive)),
                        PopupMenuItem(value: 'delete', child: Text(l.delete)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
