import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/haptics_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final ScrollController _dayScrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dayScrollController = ScrollController(initialScrollOffset: 3 * 58.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadWeatherWithLocation();
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWeatherWithLocation();
    }
  }

  Future<void> _loadWeatherWithLocation() async {
    final weatherProvider = context.read<WeatherProvider>();
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        );
        await weatherProvider.loadWeather(lat: position.latitude, lon: position.longitude);
        return;
      }
    } catch (_) {}
    await weatherProvider.loadWeather();
  }

  ImageProvider? _profileImage(AuthProvider auth) {
    final localPath = auth.localProfilePhoto;
    if (localPath != null && File(localPath).existsSync()) {
      return FileImage(File(localPath));
    }
    final url = auth.user?.profilePhotoUrl;
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniServe'),
        centerTitle: false,
        backgroundColor: const Color(0xFFB0311E),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async {
            final notificationsProvider = context.read<NotificationsProvider>();
            await _loadWeatherWithLocation();
            await notificationsProvider.loadNotifications();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 24),
                _buildDayCards(),
                const SizedBox(height: 24),
                _buildWeatherCard(),
                const SizedBox(height: 24),
                const Text(
                  'QUICK ACCESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.phone_in_talk_outlined,
                        label: 'Emergency\nContacts',
                        onTap: () => context.push('/emergency'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.map_outlined,
                        label: 'Campus\nMap',
                        onTap: () => context.push('/campus-map'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'RECENT NOTIFICATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentNotifications(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildWelcomeHeader() {
    return Consumer2<AuthProvider, NotificationsProvider>(
      builder: (context, auth, notifProvider, _) {
        final cs = Theme.of(context).colorScheme;
        final user = auth.user;
        final firstName = user?.name.split(' ').first ?? 'Student';
        final profileImg = _profileImage(auth);
        return Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: cs.surface,
              backgroundImage: profileImg,
              child: profileImg == null
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: cs.onSurface,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GOOD ${_timeOfDay().toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.secondary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    firstName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: Icon(Icons.notifications_outlined, color: cs.onSurface),
                  onPressed: () async {
                    await HapticsService.tap(context);
                    if (context.mounted) context.push('/notifications');
                  },
                ),
                if (notifProvider.unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.onSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayCards() {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final days = List.generate(14, (i) => today.add(Duration(days: i - 3)));

    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        controller: _dayScrollController,
        itemBuilder: (context, index) {
          final date = days[index];
          final isToday = date.day == today.day &&
              date.month == today.month &&
              date.year == today.year;

          const brand = Color(0xFFB0311E);
          final isDark = cs.brightness == Brightness.dark;
          return Container(
            width: 50,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB0311E), Color(0xFF8B2217)],
                    )
                  : null,
              color: isToday
                  ? null
                  : Color.fromRGBO(176, 49, 30, isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(16),
              border: isToday
                  ? null
                  : Border.all(
                      color: Color.fromRGBO(176, 49, 30, isDark ? 0.20 : 0.14)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E').format(date).substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isToday
                        ? Colors.white
                        : brand.withValues(alpha: isDark ? 0.6 : 0.55),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: isToday
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF111111)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard() {
    final cs = Theme.of(context).colorScheme;
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline),
            ),
            child: Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.secondary),
              ),
            ),
          );
        }
        if (provider.error != null || provider.weather == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 32, color: cs.secondary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WEATHER UNAVAILABLE',
                          style: TextStyle(fontSize: 11, color: cs.secondary, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text('Tap to retry',
                          style: TextStyle(color: cs.secondary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Retry weather',
                  icon: Icon(Icons.refresh, color: cs.secondary),
                  onPressed: () async {
                    await HapticsService.tap(context);
                    if (context.mounted) {
                      await _loadWeatherWithLocation();
                    }
                  },
                ),
              ],
            ),
          );
        }
        final weather = provider.weather!;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}°',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        color: cs.onSurface,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weather.description.toUpperCase()} · ${weather.cityName.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.secondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Feels like ${weather.feelsLike.round()}° · ${weather.humidity}% humidity',
                      style: TextStyle(fontSize: 12, color: cs.secondary),
                    ),
                  ],
                ),
              ),
              Text(weather.icon, style: const TextStyle(fontSize: 40)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentNotifications() {
    final cs = Theme.of(context).colorScheme;
    return Consumer<NotificationsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.secondary),
            ),
          );
        }
        if (provider.notifications.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline),
            ),
            child: Center(
              child: Text('No notifications yet',
                  style: TextStyle(color: cs.secondary, fontSize: 13)),
            ),
          );
        }
        final recent = provider.notifications.take(5).toList();
        return Column(
          children: [
            ...recent.map((n) => Semantics(
                  button: true,
                  label: n.title,
                  hint: n.isRead ? 'Notification' : 'Unread notification. Double tap to mark as read',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        if (!n.isRead && n.id != null) {
                          await provider.markAsRead(n.id!);
                          if (context.mounted) {
                            await HapticsService.confirm(context);
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM d, h:mm a').format(n.createdAt),
                                style: TextStyle(fontSize: 11, color: cs.secondary),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: cs.onSurface,
                              shape: BoxShape.circle,
                            ),
                        ),
                      ],
                    ),
                  ),
                    ),
                  ),
                )),
            if (provider.notifications.length > 5)
              TextButton(
                onPressed: () async {
                  await HapticsService.tap(context);
                  if (context.mounted) context.push('/notifications');
                },
                child: Text(
                  'VIEW ALL',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: cs.secondary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bg = Color.fromRGBO(176, 49, 30, isDark ? 0.10 : 0.06);
    final border = Color.fromRGBO(176, 49, 30, isDark ? 0.22 : 0.16);
    final iconBg = Color.fromRGBO(176, 49, 30, isDark ? 0.45 : 0.55);

    return Semantics(
      button: true,
      label: label.replaceAll('\n', ' '),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            await HapticsService.tap(context);
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF111111),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
