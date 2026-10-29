import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import 'services.dart';
import 'settings/mobile_settings.dart';
import 'ui/connect_page.dart';
import 'ui/home_page.dart';
import 'ui/manual_entry_page.dart';
import 'ui/scanner_page.dart';
import 'ui/session_detail_page.dart';
import 'ui/sessions_page.dart';
import 'ui/settings_page.dart';

final _router = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, _) => const HomePage(), routes: [
    GoRoute(path: 'connect', builder: (_, _) => const ConnectPage()),
    GoRoute(path: 'scan', builder: (_, s) => ScannerPage(single: s.uri.queryParameters['single'] == '1')),
    GoRoute(path: 'manual', builder: (_, s) => ManualEntryPage(hardware: s.uri.queryParameters['hardware'] == '1')),
    GoRoute(path: 'sessions', builder: (_, _) => const SessionsPage()),
    GoRoute(path: 'sessions/:id', builder: (_, s) => SessionDetailPage(sessionId: s.pathParameters['id']!)),
    GoRoute(path: 'settings', builder: (_, _) => const SettingsPage()),
  ]),
]);

class ScanBridgeMobileApp extends ConsumerStatefulWidget {
  const ScanBridgeMobileApp({super.key});

  @override
  ConsumerState<ScanBridgeMobileApp> createState() => _ScanBridgeMobileAppState();
}

/// Reconnects and drains the outbox whenever the app returns to foreground.
class _ScanBridgeMobileAppState extends ConsumerState<ScanBridgeMobileApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final s = ref.read(servicesProvider);
      s.link.reconnectNow();
      s.sync.kick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider).value?.theme ?? ThemeChoice.system;
    return MaterialApp.router(
      onGenerateTitle: (c) => c.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: SbTheme.light(),
      darkTheme: SbTheme.dark(),
      themeMode: switch (theme) {
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
        ThemeChoice.system => ThemeMode.system,
      },
      localizationsDelegates: SbLocalizations.localizationsDelegates,
      supportedLocales: SbLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
