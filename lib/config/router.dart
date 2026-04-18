import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/report_issue/report_issue_screen.dart';
import '../screens/report_issue/create_issue_screen.dart';
import '../screens/lost_found/lost_found_screen.dart';
import '../screens/lost_found/create_lost_found_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/emergency/emergency_contacts_screen.dart';
import '../screens/campus_map/campus_map_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/campus/campus_hub_screen.dart';
import '../screens/campus/schedule/schedule_screen.dart';
import '../screens/campus/schedule/add_class_screen.dart';
import '../screens/campus/study_rooms/study_rooms_screen.dart';
import '../screens/campus/study_rooms/room_detail_screen.dart';
import '../screens/campus/study_rooms/booking_confirmation_screen.dart';
import '../screens/campus/events/events_screen.dart';
import '../screens/campus/events/event_detail_screen.dart';
import '../screens/campus/qr_scanner/qr_scanner_screen.dart';
import '../models/study_room.dart';
import '../models/study_room_booking.dart';
import '../models/campus_event.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isInitialized = authProvider.isInitialized;
      final location = state.matchedLocation;

      // Don't redirect while initializing
      if (!isInitialized) return null;

      final isOnAuth = location == '/signup' || location == '/login';

      // If not logged in, redirect to login (unless already on auth page)
      if (!isLoggedIn && !isOnAuth) return '/login';

      // If logged in and on auth page, redirect to home
      if (isLoggedIn && isOnAuth) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Main app with bottom tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 1: Report Issues
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/report-issues',
                builder: (context, state) => const ReportIssueScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateIssueScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Tab 2: Lost & Found
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/lost-found',
                builder: (context, state) => const LostFoundScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateLostFoundScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          // Tab 4: Campus
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/campus',
                builder: (context, state) => const CampusHubScreen(),
                routes: [
                  GoRoute(
                    path: 'schedule',
                    builder: (context, state) => const ScheduleScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        builder: (context, state) => const AddClassScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'study-rooms',
                    builder: (context, state) => const StudyRoomsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => RoomDetailScreen(
                          room: state.extra as StudyRoom,
                        ),
                        routes: [
                          GoRoute(
                            path: 'confirm',
                            builder: (context, state) =>
                                BookingConfirmationScreen(
                              booking: state.extra as StudyRoomBooking,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'events',
                    builder: (context, state) => const EventsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => EventDetailScreen(
                          event: state.extra as CampusEvent,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'qr-scanner',
                    builder: (context, state) => const QrScannerScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Non-tab routes (push on top, no bottom bar)
      GoRoute(
        path: '/emergency',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/campus-map',
        builder: (context, state) => const CampusMapScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
