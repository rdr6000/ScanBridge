import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await DesktopServices.create();
  runApp(ProviderScope(
    overrides: [servicesProvider.overrideWithValue(services)],
    child: const ScanBridgeDesktopApp(),
  ));
}
