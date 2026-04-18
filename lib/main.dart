import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/issues_provider.dart';
import 'providers/lost_found_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/study_rooms_provider.dart';
import 'providers/events_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await NotificationService.initialize();

  final authProvider = AuthProvider();
  await authProvider.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final appSettingsProvider = AppSettingsProvider();
  await appSettingsProvider.initialize();

  runApp(
    UniServeApp(
      authProvider: authProvider,
      themeProvider: themeProvider,
      appSettingsProvider: appSettingsProvider,
    ),
  );
}

class UniServeApp extends StatefulWidget {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;
  final AppSettingsProvider appSettingsProvider;

  const UniServeApp({
    super.key,
    required this.authProvider,
    required this.themeProvider,
    required this.appSettingsProvider,
  });

  @override
  State<UniServeApp> createState() => _UniServeAppState();
}

class _UniServeAppState extends State<UniServeApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider.value(value: widget.appSettingsProvider),
        ChangeNotifierProvider(create: (_) => IssuesProvider()),
        ChangeNotifierProvider(create: (_) => LostFoundProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => StudyRoomsProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'UniServe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
