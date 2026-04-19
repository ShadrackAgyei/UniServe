import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/study_rooms_provider.dart';

class CampusHubScreen extends StatefulWidget {
  const CampusHubScreen({super.key});

  @override
  State<CampusHubScreen> createState() => _CampusHubScreenState();
}

class _CampusHubScreenState extends State<CampusHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().fetchEntries();
      context.read<EventsProvider>().fetchEvents();
      context.read<EventsProvider>().fetchMyRsvps();
      context.read<StudyRoomsProvider>().fetchMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final schedule = context.watch<ScheduleProvider>();
    final events = context.watch<EventsProvider>();
    final rooms = context.watch<StudyRoomsProvider>();

    final nextClass = schedule.nextClassToday;
    final nextEvent = events.nextEvent;
    final nextBooking = rooms.nextBooking;
    final nextRsvp = events.nextRsvpdEvent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus'),
        centerTitle: false,
        backgroundColor: const Color(0xFFB0311E),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HubCard(
            icon: Icons.map_outlined,
            title: 'Campus Map',
            subtitle: 'Explore buildings & locations',
            bgAlphaDark: 0.15,
            borderAlphaDark: 0.30,
            bgAlphaLight: 0.10,
            borderAlphaLight: 0.25,
            iconAlphaDark: 0.70,
            iconAlphaLight: 1.0,
            subtitleIsAccent: true,
            isDark: isDark,
            onTap: () => context.push('/campus-map'),
          ),
          const SizedBox(height: 10),
          _HubCard(
            icon: Icons.calendar_today_outlined,
            title: 'My Schedule',
            subtitle: nextClass != null
                ? '${nextClass.courseName} at ${nextClass.startTime.format(context)}'
                : 'Tap to view your timetable',
            bgAlphaDark: 0.10,
            borderAlphaDark: 0.20,
            bgAlphaLight: 0.06,
            borderAlphaLight: 0.14,
            iconAlphaDark: 0.50,
            iconAlphaLight: 0.55,
            subtitleIsAccent: false,
            isDark: isDark,
            onTap: () => context.push('/campus/schedule'),
          ),
          const SizedBox(height: 10),
          _HubCard(
            icon: Icons.event_outlined,
            title: 'Campus Events',
            subtitle: nextEvent != null
                ? '${nextEvent.title} · ${DateFormat('MMM d').format(nextEvent.eventDate)}'
                : 'Browse upcoming events',
            bgAlphaDark: 0.06,
            borderAlphaDark: 0.14,
            bgAlphaLight: 0.04,
            borderAlphaLight: 0.10,
            iconAlphaDark: 0.35,
            iconAlphaLight: 0.38,
            subtitleIsAccent: false,
            isDark: isDark,
            onTap: () => context.push('/campus/events'),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'MY BOOKINGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          _HubCard(
            icon: Icons.meeting_room_outlined,
            title: 'Study Rooms',
            subtitle: nextBooking != null
                ? '${rooms.roomNameFor(nextBooking.roomId)} · ${DateFormat('MMM d').format(nextBooking.bookingDate)} ${nextBooking.startTime.format(context)}–${nextBooking.endTime.format(context)}'
                : 'Book a study space',
            bgAlphaDark: 0.04,
            borderAlphaDark: 0.10,
            bgAlphaLight: 0.03,
            borderAlphaLight: 0.08,
            iconAlphaDark: 0.22,
            iconAlphaLight: 0.25,
            subtitleIsAccent: false,
            isDark: isDark,
            onTap: () => context.push('/campus/study-rooms'),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          _HubCard(
            icon: Icons.qr_code_2_outlined,
            title: 'Room Booking Passes',
            subtitle: 'View QR codes for your bookings',
            bgAlphaDark: 0.04,
            borderAlphaDark: 0.10,
            bgAlphaLight: 0.03,
            borderAlphaLight: 0.08,
            iconAlphaDark: 0.18,
            iconAlphaLight: 0.20,
            subtitleIsAccent: false,
            isDark: isDark,
            onTap: () => context.push('/campus/my-bookings'),
          ),
          const SizedBox(height: 10),
          _HubCard(
            icon: Icons.confirmation_number_outlined,
            title: 'Event RSVPs',
            subtitle: nextRsvp != null
                ? '${nextRsvp.title} · ${DateFormat('MMM d').format(nextRsvp.eventDate)}'
                : 'No upcoming RSVPs',
            bgAlphaDark: 0.04,
            borderAlphaDark: 0.10,
            bgAlphaLight: 0.03,
            borderAlphaLight: 0.08,
            iconAlphaDark: 0.16,
            iconAlphaLight: 0.18,
            subtitleIsAccent: false,
            isDark: isDark,
            onTap: () => context.push('/campus/events'),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double bgAlphaDark;
  final double borderAlphaDark;
  final double bgAlphaLight;
  final double borderAlphaLight;
  final double iconAlphaDark;
  final double iconAlphaLight;
  final bool subtitleIsAccent;
  final bool isDark;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bgAlphaDark,
    required this.borderAlphaDark,
    required this.bgAlphaLight,
    required this.borderAlphaLight,
    required this.iconAlphaDark,
    required this.iconAlphaLight,
    required this.subtitleIsAccent,
    required this.isDark,
    required this.onTap,
  });

  static const _brand = Color(0xFFB0311E);

  @override
  Widget build(BuildContext context) {
    final bg = Color.fromRGBO(176, 49, 30, isDark ? bgAlphaDark : bgAlphaLight);
    final border = Color.fromRGBO(176, 49, 30, isDark ? borderAlphaDark : borderAlphaLight);
    final iconBg = Color.fromRGBO(176, 49, 30, isDark ? iconAlphaDark : iconAlphaLight);
    final titleColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF111111);
    final subtitleColor = subtitleIsAccent
        ? _brand
        : (isDark
            ? Colors.white.withValues(alpha: 0.55)
            : const Color(0xFF555555));
    final chevronColor = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.20);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: chevronColor),
            ],
          ),
        ),
      ),
    );
  }
}
