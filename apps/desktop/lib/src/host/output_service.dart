import 'dart:async';

import 'package:flutter/services.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

import '../output/clipboard_output.dart';
import '../output/file_output.dart';
import '../output/keyboard_adapter.dart';
import 'host_settings.dart';

typedef StatusListener = void Function(ScanRecord scan, OutputStatus status, String? error);

/// Executes templates for received scans, one at a time (the keyboard is a
/// single shared resource), and records an honest output status.
class OutputService {
  OutputService({
    required this.scans,
    required this.sessions,
    required this.devices,
    required this.templates,
    required this.settings,
    required this.keyboard,
    required this.files,
    this.engine = const TemplateEngine(),
  }) : clipboard = ClipboardOutput(keyboard);

  final ScanRepository scans;
  final SessionRepository sessions;
  final DeviceRepository devices;
  final TemplateRepository templates;
  final HostSettingsStore settings;
  final KeyboardOutputAdapter keyboard;
  final FileOutput files;
  final ClipboardOutput clipboard;
  final TemplateEngine engine;

  final _alerts = StreamController<String>.broadcast();
  final _queue = <String>[];
  StatusListener? onStatus;
  bool _draining = false;

  /// ALERT component messages for the UI.
  Stream<String> get alerts => _alerts.stream;

  void enqueue(String scanId) {
    _queue.add(scanId);
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        await run(_queue.removeAt(0));
      }
    } finally {
      _draining = false;
    }
  }

  Future<OutputTemplate> templateFor(ScanRecord scan) async {
    if (scan.templateId != null) {
      final t = await templates.get(scan.templateId!, version: scan.templateVersion);
      if (t != null) return t;
      throw AppFailure(
        FailureCode.templateValidationFailure,
        'Template ${scan.templateId} v${scan.templateVersion} is not on this computer.',
        nextStep: 'Refresh templates on the phone, then resend.',
      );
    }
    return await templates.get(settings.current.activeTemplateId) ?? SampleTemplates.barcodeEnter();
  }

  /// Dry run: evaluates the template without side effects.
  Future<TemplateRunResult> preview(ScanRecord scan) async {
    final t = await templateFor(scan);
    return engine.run(t, await _context(scan));
  }

  Future<ExecutionContext> _context(ScanRecord scan) async {
    final session = await sessions.byId(scan.sessionId);
    final device = await devices.byId(scan.deviceId);
    return ExecutionContext.forScan(
      scan,
      sessionName: session?.name ?? '',
      deviceName: device?.name ?? scan.deviceId,
      counters: await settings.counters(),
      lookup: files,
    );
  }

  /// Runs output for [scanId]. [confirmed] allows destructive key sequences.
  Future<void> run(String scanId, {bool confirmed = false}) async {
    final scan = await scans.byId(scanId);
    if (scan == null || scan.deletedAt != null) return;
    await _set(scan, OutputStatus.pending, null);
    final OutputTemplate template;
    try {
      template = await templateFor(scan);
    } on AppFailure catch (f) {
      return _set(scan, OutputStatus.failed, f.message);
    }
    final runId = await templates.recordRunStart(scan.id, template);
    final result = await engine.run(template, await _context(scan));
    await settings.saveCounters(result.counters);
    if (!result.ok) {
      await templates.recordRunEnd(runId, status: 'failed', errorCode: result.failure!.code.name);
      return _set(scan, OutputStatus.failed, result.failure!.message);
    }
    if (result.halted) {
      await templates.recordRunEnd(runId, status: 'skipped', summary: result.warnings.join('; '));
      return _set(scan, OutputStatus.skipped, result.warnings.join('; '));
    }
    final s = settings.current;
    final destructive = result.actions.whereType<KeyPressAction>().where((a) => a.chord.isDestructive).toList();
    if (destructive.isNotEmpty && s.confirmDestructive && !confirmed) {
      await templates.recordRunEnd(runId, status: 'paused', summary: 'awaiting confirmation');
      return _set(scan, OutputStatus.paused, 'Needs confirmation: ${destructive.map((a) => a.chord).join(', ')}');
    }
    final error = await _execute(result.actions, armed: s.keyboardArmed, delay: Duration(milliseconds: s.keyDelayMs));
    final hadKeyboard = result.actions.any((a) => a.isKeyboard);
    final status = error != null
        ? OutputStatus.failed
        : (!s.keyboardArmed && hadKeyboard)
            ? OutputStatus.paused
            : OutputStatus.succeeded;
    await templates.recordRunEnd(runId, status: status.name, summary: '${result.actions.length} actions', errorCode: error == null ? null : FailureCode.outputTargetUnavailable.name);
    await _set(scan, status, error ?? (status == OutputStatus.paused ? 'Keyboard output paused' : null));
  }

  /// Executes actions in order; stops at the first failure.
  Future<String?> _execute(List<OutputAction> actions, {required bool armed, required Duration delay}) async {
    final s = settings.current;
    for (final a in actions) {
      if (a.isKeyboard && !armed) continue;
      final err = switch (a) {
        TypeTextAction(:final text) => await _type(text, delay, s.clipboardFallback),
        KeyPressAction(:final chord) => keyboard.capability.usable ? await keyboard.pressKey(chord) : keyboard.capability.reason,
        DelayAction(:final duration) => await Future<String?>.delayed(duration),
        FileAppendAction() => await files.append(a, s.csvOptions),
        ClipboardAction(:final text) => await clipboard.write(text).then((_) => null),
        BeepAction() => await SystemSound.play(SystemSoundType.alert).then((_) => null),
        AlertAction(:final message) => _alert(message),
      };
      if (err != null) return err;
    }
    return null;
  }

  Future<String?> _type(String text, Duration delay, bool clipboardFallback) async {
    if (keyboard.capability.usable) return keyboard.typeText(text, perKeyDelay: delay);
    if (clipboardFallback) return clipboard.paste(text);
    return keyboard.capability.reason;
  }

  String? _alert(String message) {
    _alerts.add(message);
    return null;
  }

  Future<void> _set(ScanRecord scan, OutputStatus status, String? error) async {
    await scans.setStatus(scan.id, output: status, outputError: () => error);
    onStatus?.call(scan, status, error);
  }

  Future<void> dispose() => _alerts.close();
}
