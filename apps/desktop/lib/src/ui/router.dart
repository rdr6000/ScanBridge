import 'package:go_router/go_router.dart';

import 'dashboard/dashboard_page.dart';
import 'devices/devices_page.dart';
import 'diagnostics/diagnostics_page.dart';
import 'diagnostics/keyboard_test_page.dart';
import 'feed/feed_page.dart';
import 'sessions/session_detail_page.dart';
import 'sessions/sessions_page.dart';
import 'settings/settings_page.dart';
import 'shell.dart';
import 'templates/template_editor_page.dart';
import 'templates/templates_page.dart';

final desktopRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
        GoRoute(path: '/feed', builder: (_, _) => const FeedPage()),
        GoRoute(path: '/sessions', builder: (_, _) => const SessionsPage()),
        GoRoute(path: '/sessions/:id', builder: (_, s) => SessionDetailPage(sessionId: s.pathParameters['id']!)),
        GoRoute(path: '/devices', builder: (_, _) => const DevicesPage()),
        GoRoute(path: '/templates', builder: (_, _) => const TemplatesPage()),
        GoRoute(path: '/templates/:id', builder: (_, s) => TemplateEditorPage(templateId: s.pathParameters['id']!)),
        GoRoute(path: '/keyboard', builder: (_, _) => const KeyboardTestPage()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
        GoRoute(path: '/diagnostics', builder: (_, _) => const DiagnosticsPage()),
      ],
    ),
  ],
);
