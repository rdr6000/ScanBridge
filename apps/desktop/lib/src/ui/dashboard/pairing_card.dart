import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../host/host_state.dart';
import '../../services.dart';

/// Shows a one-time pairing QR + typed code with a live expiry countdown.
class PairingCard extends ConsumerStatefulWidget {
  const PairingCard({super.key});

  @override
  ConsumerState<PairingCard> createState() => _PairingCardState();
}

class _PairingCardState extends ConsumerState<PairingCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final host = ref.watch(hostStateProvider).value ?? const HostState();
    final controller = ref.read(servicesProvider).host;
    final offer = host.offer;
    final remaining = offer?.expiresAt.difference(nowUtc());
    final live = offer != null && remaining != null && !remaining.isNegative;

    Widget body;
    if (!host.running) {
      body = Text(l.pairStartServerFirst);
    } else if (!live) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(host.lanMode ? l.pairHint : l.pairNeedsLan),
        const SizedBox(height: Sb.m),
        FilledButton.icon(onPressed: controller.newOffer, icon: const Icon(Icons.qr_code), label: Text(l.showPairingQr)),
      ]);
    } else {
      body = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          label: l.pairingQrLabel,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(Sb.s),
            child: QrImageView(data: offer.toUri().toString(), size: 180),
          ),
        ),
        const SizedBox(width: Sb.m),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.pairingCode, style: context.text.labelMedium),
            SelectableText(PairingOffer.displayToken(offer.token), style: context.text.headlineSmall?.copyWith(fontFamily: 'monospace')),
            const SizedBox(height: Sb.s),
            Text(l.pairExpiresIn(remaining.inSeconds), style: context.text.bodySmall),
            const SizedBox(height: Sb.s),
            Text(l.pairSingleUse, style: context.text.bodySmall),
            const SizedBox(height: Sb.m),
            Wrap(spacing: Sb.s, children: [
              OutlinedButton(onPressed: controller.newOffer, child: Text(l.regenerate)),
              TextButton(onPressed: controller.clearOffer, child: Text(l.cancel)),
            ]),
          ]),
        ),
      ]);
    }
    return SectionCard(title: l.pairTitle, child: body);
  }
}
