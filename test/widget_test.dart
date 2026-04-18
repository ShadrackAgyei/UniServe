import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uniserve/config/supabase_config.dart';
import 'package:uniserve/providers/auth_provider.dart';
import 'package:uniserve/screens/splash/splash_screen.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  });

  testWidgets('Splash screen displays app name', (WidgetTester tester) async {
    final authProvider = AuthProvider();

    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/signup', builder: (context, state) => const Scaffold(body: Text('Signup'))),
        GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('Home'))),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authProvider,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('UniServe'), findsOneWidget);
    expect(find.text('Your Campus, Your Services'), findsOneWidget);

    // Advance past the 1.5-second navigation delay
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // After navigation, should route to signup (not logged in)
    expect(find.text('Signup'), findsOneWidget);
  });
}
