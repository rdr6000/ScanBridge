import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../../host/host_state.dart';
import '../../services.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  Future<void> _forgetAll(BuildContext context, WidgetRef ref, List<Device> devices) async {
    final l = context.l10n;
    final ok = await confirmAction(context, title: l.forgetAllTitle, message: l.forgetAllBody(devices.length), confirmLabel: l.forgetAll, destructive: true);
    if (!ok) return;
    for (final d in devices) {
      await ref.read(servicesProvider).host.forget(d.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final online = ref.watch(hostStateProvider).value?.clients ?? const <String, ConnectedClient>{};
    return StreamBuilder<List<Device>>(
      stream: services.devices.watchAll(),
      builder: (context, snap) {
        final devices = snap.data ?? const [];
        return ListView(padding: const EdgeInsets.all(Sb.l), children: [
          Row(children: [
            Expanded(child: Text(l.navDevices, style: context.text.headlineSmall)),
            if (devices.isNotEmpty)
              TextButton.icon(
                onPressed: () => _forgetAll(context, ref, devices),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(l.forgetAll),
              ),
          ]),
          const SizedBox(height: Sb.m),
          if (devices.isEmpty)
            EmptyState(icon: Icons.smartphone, title: l.noDevicesTitle, message: l.noDevicesHint)
          else
            for (final d in devices) Padding(padding: const EdgeInsets.only(bottom: Sb.s), child: _DeviceCard(device: d, client: online[d.id])),
        ]);
      },
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({required this.device, this.client});
  final Device device;
  final ConnectedClient? client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.read(servicesProvider);
    final (label, tone) = switch (device.status) {
      DeviceStatus.paired when client != null => (l.deviceOnline, Tone.success),
      DeviceStatus.paired => (l.devicePaired, Tone.info),
      DeviceStatus.revoked => (l.deviceRevoked, Tone.error),
      DeviceStatus.pending => (l.devicePending, Tone.warning),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sb.m),
        child: Row(children: [
          Icon(device.platform == 'ios' ? Icons.phone_iphone : Icons.phone_android, size: 32),
          const SizedBox(width: Sb.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(device.name, style: context.text.titleMedium)),
                const SizedBox(width: Sb.s),
                StatusChip(label, tone),
              ]),
              Text([
                device.platform,
                if (client != null) client!.address,
                if (device.lastSeenAt != null) l.lastSeen(formatLocal(context, device.lastSeenAt!)),
              ].join(' · ')),
              if (device.status == DeviceStatus.paired)
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.allowScans),
                  value: device.canSubmitScans,
                  onChanged: (v) => services.devices.setCanSubmit(device.id, v),
                ),
            ]),
          ),
          PopupMenuButton<String>(
            tooltip: l.moreActions,
            onSelected: (a) async {
              switch (a) {
                case 'rename':
                  final name = await promptText(context, title: l.rename, initial: device.name);
                  if (name != null && name.isNotEmpty) await services.devices.rename(device.id, name);
                case 'revoke':
                  if (context.mounted && await confirmAction(context, title: l.revoke, message: l.revokeBody(device.name), confirmLabel: l.revoke, destructive: true)) {
                    await services.host.revoke(device.id);
                  }
                case 'forget':
                  if (context.mounted && await confirmAction(context, title: l.forget, message: l.forgetBody(device.name), confirmLabel: l.forget, destructive: true)) {
                    await services.host.forget(device.id);
                  }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text(l.rename)),
              if (device.status == DeviceStatus.paired) PopupMenuItem(value: 'revoke', child: Text(l.revoke)),
              PopupMenuItem(value: 'forget', child: Text(l.forget)),
            ],
          ),
        ]),
      ),
    );
  }
}
