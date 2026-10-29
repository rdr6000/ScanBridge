import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scanbridge_storage/scanbridge_storage.dart';

import 'capture/capture_service.dart';
import 'connection/connection_manager.dart';
import 'connection/host_link.dart';
import 'connection/sync_service.dart';
import 'settings/mobile_settings.dart';

/// Composition root for the phone app.
class MobileServices {
  MobileServices._(this.db, this.settings, this.link, this.sync, this.capture);

  final ScanBridgeDatabase db;
  final MobileSettingsStore settings;
  final ConnectionManager link;
  final SyncService sync;
  final CaptureService capture;

  late final scans = ScanRepository(db);
  late final sessions = SessionRepository(db);
  late final outbox = OutboxRepository(db);
  late final templates = TemplateRepository(db);

  static Future<MobileServices> create() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final db = ScanBridgeDatabase.open(File(p.join(dir.path, 'scanbridge_mobile.db')));
    final settings = MobileSettingsStore(SettingsRepository(db));
    await settings.load();
    final link = ConnectionManager(CredentialStore(), deviceName: () => settings.current.deviceName, platform: Platform.operatingSystem);
    final scans = ScanRepository(db);
    final sessions = SessionRepository(db);
    final templates = TemplateRepository(db);
    final sync = SyncService(
      link: link,
      scans: scans,
      sessions: sessions,
      outbox: OutboxRepository(db),
      templates: templates,
      settings: settings,
    )..start();
    final capture = CaptureService(scans: scans, sessions: sessions, templates: templates, settings: settings, link: link, sync: sync);
    await link.init();
    return MobileServices._(db, settings, link, sync, capture);
  }
}

final servicesProvider = Provider<MobileServices>((ref) => throw UnimplementedError('override in main'));

final linkStateProvider = StreamProvider<LinkState>((ref) async* {
  final link = ref.watch(servicesProvider).link;
  yield link.state;
  yield* link.states;
});

final settingsProvider = StreamProvider<MobileSettings>((ref) => ref.watch(servicesProvider).settings.watch());
