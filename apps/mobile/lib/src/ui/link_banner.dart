import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../connection/connection_manager.dart';
import '../services.dart';

/// Persistent connection + queue state; tapping opens the connect screen.
class LinkBanner extends ConsumerWidget {
  const LinkBanner({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(linkStateProvider).value ?? const LinkState(LinkStatus.notPaired);
    final services = ref.watch(servicesProvider);
    final (label, tone, icon) = switch (state.status) {
      LinkStatus.connected => (l.linkConnected(state.serverName ?? ''), Tone.success, Icons.link),
      LinkStatus.connecting => (l.linkConnecting, Tone.info, Icons.sync),
      LinkStatus.reconnecting => (l.linkReconnecting, Tone.warning, Icons.sync_problem),
      LinkStatus.awaitingApproval => (l.linkAwaitingApproval, Tone.info, Icons.hourglass_top),
      LinkStatus.disconnected => (l.linkDisconnected, Tone.neutral, Icons.link_off),
      LinkStatus.error => (l.linkError, Tone.error, Icons.error_outline),
      LinkStatus.notPaired => (l.linkNotPaired, Tone.neutral, Icons.link_off),
    };
    return InkWell(
      onTap: () => context.push('/connect'),
      borderRadius: BorderRadius.circular(Sb.radius),
      child: Row(children: [
        StatusChip(label, tone, icon: icon),
        const Spacer(),
        StreamBuilder<int>(
          stream: services.outbox.watchPending(),
          builder: (_, s) => (s.data ?? 0) == 0 ? const SizedBox.shrink() : StatusChip(l.pendingCount(s.data!), Tone.warning, icon: Icons.outbox),
        ),
        if (!compact && state.failure != null) ...[
          const SizedBox(width: Sb.s),
          Icon(Icons.info_outline, color: context.statusColors.error, semanticLabel: state.failure!.message),
        ],
      ]),
    );
  }
}
