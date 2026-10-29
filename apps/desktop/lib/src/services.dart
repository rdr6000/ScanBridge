import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';
import 'package:scanbridge_template_engine/scanbridge_template_engine.dart';

import 'host/host_controller.dart';
import 'host/host_settings.dart';
import 'host/host_state.dart';
import 'host/output_service.dart';
import 'host/secret_store.dart';
import 'output/file_output.dart';
import 'output/keyboard_adapter.dart';

/// Composition root for the desktop host.
class DesktopServices {
  DesktopServices._({
    required this.dataDir,
    required this.db,
    required this.settings,
    required this.host,
    required this.output,
    required this.keyboard,
    required this.files,
  });

  final Directory dataDir;
  final ScanBridgeDatabase db;
  final HostSettingsStore settings;
  final HostController host;
  final OutputService output;
  final KeyboardOutputAdapter keyboard;
  final FileOutput files;

  late final scans = ScanRepository(db);
  late final sessions = SessionRepository(db);
  late final devices = DeviceRepository(db);
  late final templates = TemplateRepository(db);
  late final audit = AuditRepository(db);

  File get databaseFile => File(p.join(dataDir.path, 'scanbridge.db'));

  static Future<DesktopServices> create() async {
    final dataDir = await getApplicationSupportDirectory();
    await dataDir.create(recursive: true);
    final docs = await getApplicationDocumentsDirectory();
    final db = ScanBridgeDatabase.open(File(p.join(dataDir.path, 'scanbridge.db')));
    final settings = HostSettingsStore(SettingsRepository(db));
    await settings.loadWithDefaults(defaultOutputDir: p.join(docs.path, 'ScanBridge'));
    final templates = TemplateRepository(db);
    await templates.seedIfEmpty(SampleTemplates.all());
    final keyboard = createKeyboardAdapter();
    final files = FileOutput(settings.current.outputDirectory);
    final scans = ScanRepository(db);
    final sessions = SessionRepository(db);
    final devices = DeviceRepository(db);
    final output = OutputService(
      scans: scans,
      sessions: sessions,
      devices: devices,
      templates: templates,
      settings: settings,
      keyboard: keyboard,
      files: files,
    );
    final host = HostController(
      settings: settings,
      secrets: SecureSecretStore(),
      devices: devices,
      scans: scans,
      sessions: sessions,
      templates: templates,
      audit: AuditRepository(db),
      output: output,
    );
    await host.init();
    settings.changes.listen((s) => files.baseDirectory = s.outputDirectory);
    return DesktopServices._(
      dataDir: dataDir,
      db: db,
      settings: settings,
      host: host,
      output: output,
      keyboard: keyboard,
      files: files,
    );
  }
}

final servicesProvider = Provider<DesktopServices>((ref) => throw UnimplementedError('override in main'));

final hostStateProvider = StreamProvider<HostState>((ref) async* {
  final host = ref.watch(servicesProvider).host;
  yield host.state;
  yield* host.states;
});

final settingsProvider = StreamProvider<HostSettings>((ref) async* {
  final s = ref.watch(servicesProvider).settings;
  yield s.current;
  yield* s.changes;
});
