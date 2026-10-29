import 'package:flutter/services.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

import '../connection/connection_manager.dart';
import '../connection/sync_service.dart';
import '../settings/mobile_settings.dart';

/// Result of checking a code before it is stored.
class CaptureCheck {
  const CaptureCheck(this.outcome, this.template);
  final ValidationOutcome outcome;

  /// Template whose prompts must be answered before saving, if any.
  final OutputTemplate? template;
  bool get needsPrompts => template != null && template!.prompts.isNotEmpty;
}

/// Validates, persists (scan + outbox in one transaction) and triggers sync.
class CaptureService {
  CaptureService({
    required this.scans,
    required this.sessions,
    required this.templates,
    required this.settings,
    required this.link,
    required this.sync,
  });

  final ScanRepository scans;
  final SessionRepository sessions;
  final TemplateRepository templates;
  final MobileSettingsStore settings;
  final ConnectionManager link;
  final SyncService sync;

  /// Active session, creating a dated one if none is selected.
  Future<ScanSession> activeSession() async {
    final id = settings.current.activeSessionId;
    final existing = id == null ? null : await sessions.byId(id);
    if (existing != null && !existing.isArchived) return existing;
    final now = DateTime.now();
    final created = await sessions.create('Session ${now.year}-${_two(now.month)}-${_two(now.day)} ${_two(now.hour)}:${_two(now.minute)}', deviceId: link.deviceId);
    await settings.update((s) => s.copyWith(activeSessionId: () => created.id));
    return created;
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  Future<CaptureCheck> check(String value, Symbology symbology) async {
    final session = await activeSession();
    final duplicate = await scans.valueExistsInSession(session.id, value);
    final outcome = ScanValidator(settings.current.rules).validate(value, symbology, isDuplicate: duplicate);
    final templateId = settings.current.effectiveTemplateId;
    final template = templateId == null ? null : await templates.get(templateId);
    return CaptureCheck(outcome, template);
  }

  /// Persists before any network attempt. Unpaired phones keep scans local.
  Future<ScanRecord> save({
    required String value,
    required Symbology symbology,
    required ScanSource source,
    required ValidationOutcome outcome,
    OutputTemplate? template,
    Map<String, String> values = const {},
    String? quantity,
  }) async {
    final session = await activeSession();
    final paired = link.link != null;
    final scan = ScanRecord(
      id: newId(),
      sessionId: session.id,
      deviceId: link.deviceId,
      rawValue: value,
      symbology: symbology,
      quantity: quantity ?? values['qty'] ?? settings.current.defaultQuantity,
      capturedAt: nowUtc(),
      source: source,
      validationStatus: outcome.status,
      deliveryStatus: paired ? DeliveryStatus.queued : DeliveryStatus.localOnly,
      templateId: template?.id,
      templateVersion: template?.version,
      values: values,
    );
    paired ? await scans.captureWithOutbox(scan, session) : await scans.captureLocal(scan, session);
    sync.kick();
    return scan;
  }

  /// Haptic and sound feedback per settings.
  Future<void> feedback({required bool ok}) async {
    final s = settings.current;
    if (s.haptics) ok ? await HapticFeedback.mediumImpact() : await HapticFeedback.heavyImpact();
    if (s.sound) await SystemSound.play(ok ? SystemSoundType.click : SystemSoundType.alert);
  }
}
