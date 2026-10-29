import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../connection/connection_manager.dart';
import '../services.dart';
import 'link_banner.dart';

/// Pair by scanning the desktop QR or typing host/port/code; manage the link.
class ConnectPage extends ConsumerStatefulWidget {
  const ConnectPage({super.key});

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '${ProtocolLimits.defaultPort}');
  final _code = TextEditingController();
  var _working = false;
  MobileScannerController? _qr;

  bool get _scanning => _qr != null;

  void _stopQr() {
    _qr?.dispose();
    _qr = null;
  }

  @override
  void dispose() {
    _stopQr();
    _host.dispose();
    _port.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _pair(PairingOffer offer) async {
    setState(() {
      _working = true;
      _stopQr();
    });
    final failure = await ref.read(servicesProvider).link.pair(offer);
    if (!mounted) return;
    setState(() => _working = false);
    final l = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure == null ? l.pairedOk : '${failure.message} ${failure.nextStep ?? ''}')));
    if (failure == null) ref.read(servicesProvider).sync.refreshTemplates();
  }

  void _manual() {
    final port = int.tryParse(_port.text.trim());
    final host = _host.text.trim();
    final code = PairingOffer.normalizeToken(_code.text);
    if (host.isEmpty || port == null || code.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.manualPairInvalid)));
      return;
    }
    _pair(PairingOffer(serverId: '', serverName: host, hosts: [host], port: port, token: code, expiresAt: DateTime.utc(9999)));
  }

  void _onDetect(BarcodeCapture c) {
    if (_working) return;
    for (final b in c.barcodes) {
      final offer = PairingOffer.tryParse(b.rawValue ?? '');
      if (offer != null) {
        _pair(offer);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final link = ref.read(servicesProvider).link;
    final state = ref.watch(linkStateProvider).value ?? const LinkState(LinkStatus.notPaired);
    return Scaffold(
      appBar: AppBar(title: Text(l.connectTitle)),
      body: ListView(padding: const EdgeInsets.all(Sb.m), children: [
        const LinkBanner(),
        if (state.failure != null) ...[const SizedBox(height: Sb.s), FailureBanner(state.failure!, onRetry: link.reconnectNow)],
        if (_working || state.status == LinkStatus.awaitingApproval) ...[
          const SizedBox(height: Sb.m),
          const LinearProgressIndicator(),
          Text(state.status == LinkStatus.awaitingApproval ? l.approveOnComputer : l.linkConnecting),
        ],
        if (link.link != null) ...[
          const SizedBox(height: Sb.m),
          SectionCard(
            title: l.pairedComputer,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${link.link!.serverName} · ${link.link!.hosts.join(', ')}:${link.link!.port}'),
              const SizedBox(height: Sb.s),
              Wrap(spacing: Sb.s, children: [
                if (state.connected)
                  OutlinedButton(onPressed: link.disconnect, child: Text(l.disconnect))
                else
                  FilledButton(onPressed: link.connect, child: Text(l.connect)),
                TextButton(
                  onPressed: () async {
                    if (await confirmAction(context, title: l.forget, message: l.forgetHostBody, confirmLabel: l.forget, destructive: true)) {
                      await link.forget();
                    }
                  },
                  child: Text(l.forget),
                ),
              ]),
            ]),
          ),
        ],
        const SizedBox(height: Sb.m),
        SectionCard(
          title: l.scanPairingQr,
          child: _scanning
              ? SizedBox(height: 280, child: MobileScanner(onDetect: _onDetect, controller: _qr))
              : FilledButton.icon(onPressed: () => setState(() => _qr = MobileScannerController(formats: const [BarcodeFormat.qrCode])), icon: const Icon(Icons.qr_code_scanner), label: Text(l.scanPairingQr)),
        ),
        const SizedBox(height: Sb.m),
        SectionCard(
          title: l.manualPairTitle,
          child: Column(children: [
            TextField(controller: _host, keyboardType: TextInputType.url, decoration: InputDecoration(labelText: l.hostAddress, hintText: '192.168.1.20')),
            const SizedBox(height: Sb.s),
            TextField(controller: _port, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.port)),
            const SizedBox(height: Sb.s),
            TextField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: l.pairingCode, hintText: 'ABCDE-12345')),
            const SizedBox(height: Sb.s),
            Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _working ? null : _manual, child: Text(l.pair))),
          ]),
        ),
        const SizedBox(height: Sb.m),
        Text(l.connectTroubleshooting, style: context.text.bodySmall),
      ]),
    );
  }
}
