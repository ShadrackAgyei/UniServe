import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/campus_event.dart';
import '../../../providers/events_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../services/notification_service.dart';

class EventDetailScreen extends StatefulWidget {
  final CampusEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int? _rsvpCount;
  bool _loadingCount = true;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().fetchMyRsvps();
      _loadRsvpCount();
    });
  }

  Future<void> _loadRsvpCount() async {
    if (!mounted) return;
    setState(() => _loadingCount = true);
    try {
      final count = await context
          .read<EventsProvider>()
          .getRsvpCount(widget.event.id);
      if (mounted) setState(() => _rsvpCount = count);
    } catch (_) {}
    if (mounted) setState(() => _loadingCount = false);
  }

  bool get _isFull =>
      widget.event.capacity != null &&
      _rsvpCount != null &&
      _rsvpCount! >= widget.event.capacity!;

  Future<void> _rsvp() async {
    final isOnline = context.read<ConnectivityProvider>().isOnline;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }
    setState(() => _actionInProgress = true);
    try {
      await context.read<EventsProvider>().rsvpToEvent(widget.event.id);
      NotificationService.showNotification(
        id: widget.event.id.hashCode.abs() % 2147483647,
        title: 'RSVP Confirmed!',
        body: '${widget.event.title} · ${DateFormat('MMM d').format(widget.event.eventDate)}',
      );
      _loadRsvpCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not RSVP: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _cancelRsvp() async {
    final isOnline = context.read<ConnectivityProvider>().isOnline;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }
    setState(() => _actionInProgress = true);
    try {
      await context
          .read<EventsProvider>()
          .cancelRsvp(widget.event.id);
      _loadRsvpCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel RSVP: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, MMMM d yyyy').format(widget.event.eventDate);
    final timeStr = widget.event.startTime.format(context);
    final rsvps = context.watch<EventsProvider>().myRsvps;
    final myRsvp = rsvps[widget.event.id];
    final hasRsvp = myRsvp != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.event.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.event.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.event.imageUrl!,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            widget.event.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.calendar_today, text: dateStr),
          _InfoRow(icon: Icons.access_time, text: timeStr),
          _InfoRow(
              icon: Icons.location_on, text: widget.event.location),
          _InfoRow(
              icon: Icons.person,
              text: 'Organised by ${widget.event.organizer}'),
          if (widget.event.capacity != null)
            _InfoRow(
              icon: Icons.people,
              text: _loadingCount
                  ? 'Loading...'
                  : '$_rsvpCount / ${widget.event.capacity} attending',
            ),
          const SizedBox(height: 16),
          Text(widget.event.description),
          const SizedBox(height: 24),
          if (hasRsvp) ...[
            Card(
              color:
                  Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("You're going!",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                        'Show this QR code at the event entrance'),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: myRsvp.qrToken,
                      version: QrVersions.auto,
                      size: 180,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Open QR Scanner'),
                      onPressed: () =>
                          context.push('/campus/qr-scanner'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed:
                          _actionInProgress ? null : _cancelRsvp,
                      child: _actionInProgress
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Text('Cancel RSVP',
                              style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isFull || _actionInProgress ? null : _rsvp,
                child: _actionInProgress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isFull ? 'Event Full' : 'RSVP'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
