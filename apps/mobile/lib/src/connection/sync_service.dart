import 'dart:async';

import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_protocol/scanbridge_protocol.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

import '../settings/mobile_settings.dart';
import 'connection_manager.dart';

/// Drains the durable outbox over the link and applies host messages.
/// Resends always reuse the original scan id, so the host stays idempotent.
class SyncService {
  SyncService({
    required this.link,
    required this.scans,
    required this.sessions,
    required this.outbox,
    required this.templates,
    required this.settings,
  });

  final ConnectionManager link;
  final ScanRepository scans;
  final SessionRepository sessions;
  final OutboxRepository outbox;
  final TemplateRepository templates;
  final MobileSettingsStore settings;

  final _waiting = <String, Completer<Envelope>>{};
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _timer;
  var _draining = false;

  static const ackTimeout = Duration(seconds: 10);

  void start() {
    _subs
      ..add(link.messages.listen(_onMessage))
      ..add(link.states.listen((s) {
        if (s.connected) kick();
        if (!s.connected) _failWaiting();
      }));
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => kick());
  }

  void kick() {
    if (link.state.connected) unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (link.state.connected) {
        final due = await outbox.due(nowUtc(), limit: 20);
        if (due.isEmpty) break;
        for (final item in due) {
          if (!await _sendOne(item)) return;
        }
      }
    } finally {
      _draining = false;
    }
  }

  /// Returns false when the link looks broken and draining should stop.
  Future<bool> _sendOne(OutboxItem item) async {
    final scan = await scans.byId(item.scanId);
    if (scan == null || scan.deletedAt != null) {
      await outbox.complete(item.scanId);
      return true;
    }
    final session = await sessions.byId(scan.sessionId);
    final waiter = _waiting[scan.id] = Completer<Envelope>();
    final sent = link.send(Envelope(
      type: MessageType.scanSubmit,
      payload: ScanSubmit.fromRecord(scan, session?.name ?? 'Session').toJson(),
    ));
    if (!sent) {
      _waiting.remove(scan.id);
      await outbox.recordFailure(item, 'not connected');
      return false;
    }
    try {
      final reply = await waiter.future.timeout(ackTimeout);
      if (reply.type == MessageType.scanAck) {
        await scans.setStatus(scan.id, delivery: DeliveryStatus.received);
      } else {
        final err = ErrorPayload.fromJson(reply.payload);
        if (err.code == FailureCode.storageFailure) {
          await outbox.recordFailure(item, err.message);
          return true;
        }
        await scans.setStatus(scan.id, delivery: DeliveryStatus.rejected, outputError: () => err.message);
      }
      await outbox.complete(scan.id);
      return true;
    } on TimeoutException {
      await outbox.recordFailure(item, 'no acknowledgement');
      return false;
    } finally {
      _waiting.remove(scan.id);
    }
  }

  void _failWaiting() {
    for (final c in _waiting.values) {
      if (!c.isCompleted) c.completeError(TimeoutException('disconnected'));
    }
  }

  Future<void> _onMessage(Envelope env) async {
    switch (env.type) {
      case MessageType.scanAck || MessageType.scanReject:
        final id = env.payload['scanId'] as String?;
        final c = _waiting[id];
        if (c != null && !c.isCompleted) c.complete(env);
      case MessageType.deliveryStatus:
        final d = DeliveryStatusPayload.fromJson(env.payload);
        await scans.setStatus(d.scanId, output: d.outputStatus, outputError: () => d.error);
      case MessageType.templateList:
        await _cacheTemplates(TemplateListPayload.fromJson(env.payload));
      case MessageType.deviceRevoke:
        await link.forget();
    }
  }

  Future<void> _cacheTemplates(TemplateListPayload p) async {
    final parsed = <OutputTemplate>[];
    for (final json in p.templates) {
      try {
        parsed.add(OutputTemplate.fromJson(json));
      } on TemplateFormatException {
        // Skip templates this app version cannot read; the host still has them.
      }
    }
    await templates.replaceCache(parsed);
    await settings.update((s) => s.copyWith(hostActiveTemplateId: () => p.activeTemplateId));
  }

  /// Asks the host for fresh templates.
  void refreshTemplates() => link.send(Envelope(type: MessageType.templateList, payload: const {}));

  void dispose() {
    _timer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
  }
}
