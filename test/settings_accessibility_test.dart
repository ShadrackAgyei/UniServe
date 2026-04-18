import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniserve/models/user_profile.dart';
import 'package:uniserve/providers/app_settings_provider.dart';
import 'package:uniserve/providers/auth_provider.dart';
import 'package:uniserve/providers/theme_provider.dart';
import 'package:uniserve/screens/profile/profile_screen.dart';
import 'package:uniserve/screens/settings/settings_screen.dart';
import 'package:uniserve/screens/shell/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('profile shows settings button and navigates to settings', (tester) async {
    final auth = _FakeAuthProvider();
    final settings = AppSettingsProvider();
    await settings.initialize();

    final router = GoRouter(
      routes: [
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      ],
      initialLocation: '/profile',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<AppSettingsProvider>.value(value: settings),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Settings'), findsOneWidget);
    router.push('/settings');
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('settings toggle updates provider state', (tester) async {
    final settings = AppSettingsProvider();
    await settings.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettingsProvider>.value(
        value: settings,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(settings.hapticsEnabled, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(settings.hapticsEnabled, isFalse);
  });

  testWidgets('bottom navigation exposes button semantics and selected state', (tester) async {
    final handle = tester.ensureSemantics();
    final router = GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/issues', builder: (context, state) => const Scaffold(body: Text('Issues'))),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/lost', builder: (context, state) => const Scaffold(body: Text('Lost'))),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/profile', builder: (context, state) => const Scaffold(body: Text('Profile'))),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsProvider(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final homeSemantics = tester.getSemantics(find.byTooltip('HOME'));
    final issuesSemantics = tester.getSemantics(find.byTooltip('ISSUES'));

    expect(homeSemantics.label, 'HOME tab\nHOME');
    expect(homeSemantics.flagsCollection.isButton, isTrue);
    expect(homeSemantics.flagsCollection.isSelected, ui.Tristate.isTrue);

    expect(issuesSemantics.label, 'ISSUES tab');
    expect(issuesSemantics.flagsCollection.isButton, isTrue);
    expect(issuesSemantics.flagsCollection.isSelected, isNot(ui.Tristate.isTrue));

    handle.dispose();
  });
}

class _FakeAuthProvider extends AuthProvider {
  @override
  bool get isInitialized => true;

  @override
  bool get isLoggedIn => true;

  @override
  UserProfile? get user => UserProfile(
        id: 'u1',
        studentId: '12345',
        name: 'Test Student',
        email: 'test@example.com',
      );
}
