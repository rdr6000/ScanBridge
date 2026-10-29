import 'package:flutter/material.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

/// One scan row: value, metadata line and status chips.
class ScanListTile extends StatelessWidget {
  const ScanListTile({super.key, required this.scan, this.selected = false, this.onTap, this.leading, this.subtitlePrefix});
  final ScanRecord scan;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final String? subtitlePrefix;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final meta = [
      ?subtitlePrefix,
      formatLocal(context, scan.capturedAt),
      scan.symbology.name,
      '${l.quantityShort} ${scan.quantity}',
    ].join(' · ');
    return ListTile(
      selected: selected,
      leading: leading,
      onTap: onTap,
      title: Text(scan.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'monospace')),
      subtitle: Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: ScanStatusChips(scan),
    );
  }
}
