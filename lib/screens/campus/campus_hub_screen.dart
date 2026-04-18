import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/events_provider.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final schedule = context.watch<ScheduleProvider>();
    final events = context.watch<EventsProvider>();
    final nextClass = schedule.nextClassToday;
    final nextEvent = events.nextEvent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HubCard(
            icon: Icons.calendar_today_outlined,
            title: 'My Schedule',
            subtitle: nextClass != null
                ? '${nextClass.courseName} at ${nextClass.startTime.format(context)}'
                : 'Tap to view your timetable',
            color: cs.primaryContainer,
            onTap: () => context.push('/campus/schedule'),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.event_outlined,
            title: 'Campus Events',
            subtitle: nextEvent != null
                ? '${nextEvent.title} · ${DateFormat('MMM d').format(nextEvent.eventDate)}'
                : 'Browse upcoming events',
            color: cs.secondaryContainer,
            onTap: () => context.push('/campus/events'),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.meeting_room_outlined,
            title: 'Study Rooms',
            subtitle: 'Find and book a study space',
            color: cs.tertiaryContainer,
            onTap: () => context.push('/campus/study-rooms'),
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
  final Color color;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: color,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, size: 32, color: cs.onSurface),
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurface.withAlpha(179))),
        trailing:
            Icon(Icons.chevron_right, color: cs.onSurface.withAlpha(128)),
        onTap: onTap,
      ),
    );
  }
}
