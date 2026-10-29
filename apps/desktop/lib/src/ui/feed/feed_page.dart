import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../services.dart';
import '../widgets/scan_detail_panel.dart';
import '../widgets/scan_list_tile.dart';

enum FeedFilter { all, failed, paused, duplicates }

/// Live scan feed across all sessions with search, filters and details.
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  var _filter = FeedFilter.all;
  String? _selectedId;
  late Stream<List<ScanRecord>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _query();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters;
    if (q['failed'] == '1' && _filter == FeedFilter.all) _setFilter(FeedFilter.failed);
    if (q['focus'] == '1') WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Stream<List<ScanRecord>> _query() => ref.read(servicesProvider).scans.watch(ScanFilter(
    text: _search.text.trim(),
    outputStatuses: switch (_filter) {
      FeedFilter.failed => {OutputStatus.failed},
      FeedFilter.paused => {OutputStatus.paused},
      _ => const {},
    },
    validation: _filter == FeedFilter.duplicates ? ValidationStatus.duplicate : null,
  ));

  void _setFilter(FeedFilter f) => setState(() {
    _filter = f;
    _stream = _query();
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final wide = MediaQuery.sizeOf(context).width >= 1200;
    return StreamBuilder<List<ScanRecord>>(
      stream: _stream,
      builder: (context, snap) {
        final scans = snap.data ?? const [];
        final selected = scans.where((s) => s.id == _selectedId).firstOrNull;
        final list = Column(children: [
          Padding(
            padding: const EdgeInsets.all(Sb.m),
            child: Column(children: [
              TextField(
                controller: _search,
                focusNode: _searchFocus,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchScans),
                onChanged: (_) => setState(() => _stream = _query()),
              ),
              const SizedBox(height: Sb.s),
              Wrap(spacing: Sb.s, children: [
                for (final f in FeedFilter.values)
                  ChoiceChip(
                    label: Text(switch (f) {
                      FeedFilter.all => l.filterAll,
                      FeedFilter.failed => l.filterFailed,
                      FeedFilter.paused => l.filterPaused,
                      FeedFilter.duplicates => l.filterDuplicates,
                    }),
                    selected: _filter == f,
                    onSelected: (_) => _setFilter(f),
                  ),
              ]),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: scans.isEmpty
                ? EmptyState(icon: Icons.dynamic_feed_outlined, title: l.noScansTitle, message: l.noScansDesktopHint)
                : ListView.builder(
                    itemCount: scans.length,
                    itemBuilder: (_, i) => ScanListTile(
                      scan: scans[i],
                      selected: scans[i].id == _selectedId,
                      onTap: () => wide ? setState(() => _selectedId = scans[i].id) : _openSheet(scans[i]),
                    ),
                  ),
          ),
        ]);
        if (!wide) return list;
        return Row(children: [
          Expanded(flex: 3, child: list),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 2,
            child: selected == null
                ? EmptyState(icon: Icons.touch_app_outlined, title: l.selectScanTitle, message: l.selectScanHint)
                : ScanDetailPanel(scan: selected, onDeleted: () => setState(() => _selectedId = null)),
          ),
        ]);
      },
    );
  }

  void _openSheet(ScanRecord scan) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SizedBox(height: MediaQuery.sizeOf(c).height * .7, child: ScanDetailPanel(scan: scan, onDeleted: () => Navigator.pop(c))),
  );
}
