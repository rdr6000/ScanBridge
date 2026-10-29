import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import 'host/host_settings.dart';
import 'services.dart';
import 'ui/router.dart';

class ScanBridgeDesktopApp extends ConsumerWidget {
  const ScanBridgeDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider).value?.theme ?? ThemePreference.system;
    return MaterialApp.router(
      onGenerateTitle: (c) => c.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: SbTheme.light(),
      darkTheme: SbTheme.dark(),
      themeMode: switch (theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      },
      localizationsDelegates: SbLocalizations.localizationsDelegates,
      supportedLocales: SbLocalizations.supportedLocales,
      routerConfig: desktopRouter,
    );
  }
}
