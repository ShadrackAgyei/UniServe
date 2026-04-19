import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/study_room.dart';
import '../../../models/study_room_booking.dart';
import '../../../providers/study_rooms_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../services/notification_service.dart';

class RoomDetailScreen extends StatefulWidget {
  final StudyRoom room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedSlot;
  List<StudyRoomBooking> _existingBookings = [];
  bool _loadingSlots = false;
  bool _booking = false;

  static const _slotHours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    try {
      final bookings = await context
          .read<StudyRoomsProvider>()
          .getBookingsForRoom(widget.room.id, _selectedDate);
      if (mounted) setState(() => _existingBookings = bookings);
    } catch (_) {}
    if (mounted) setState(() => _loadingSlots = false);
  }

  bool _isBooked(int hour) {
    return _existingBookings.any((b) => b.startTime.hour == hour);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
      _loadSlots();
    }
  }

  Future<void> _book() async {
    if (_selectedSlot == null) return;
    final isOnline = context.read<ConnectivityProvider>().isOnline;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }
    setState(() => _booking = true);
    try {
      final booking =
          await context.read<StudyRoomsProvider>().createBooking(
                roomId: widget.room.id,
                date: _selectedDate,
                start: _selectedSlot!,
                end: TimeOfDay(hour: _selectedSlot!.hour + 1, minute: 0),
              );
      if (mounted) {
        final slotStr = _selectedSlot!.format(context);
        NotificationService.showNotification(
          id: booking.id.hashCode.abs() % 2147483647,
          title: 'Room Booked!',
          body: '${widget.room.name} · ${_selectedDate.day}/${_selectedDate.month} at $slotStr',
        );
        context.push(
          '/campus/study-rooms/${widget.room.id}/confirm',
          extra: booking,
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('duplicate')
            ? 'That slot is already taken'
            : 'Could not complete booking: $e';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.room.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RoomInfo(room: widget.room),
                const SizedBox(height: 16),
                Row(children: [
                  Text('Date:',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    onPressed: _pickDate,
                  ),
                ]),
                const SizedBox(height: 12),
                Text('Available Slots',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                if (_loadingSlots)
                  const Center(child: CircularProgressIndicator())
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slotHours.map((h) {
                      final booked = _isBooked(h);
                      final slot = TimeOfDay(hour: h, minute: 0);
                      return ChoiceChip(
                        label: Text(
                            '${h.toString().padLeft(2, '0')}:00'),
                        selected: _selectedSlot?.hour == h,
                        onSelected:
                            booked ? null : (_) => setState(() => _selectedSlot = slot),
                        disabledColor: Colors.grey.shade300,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _selectedSlot == null || _booking ? null : _book,
                child: _booking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Book This Slot'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomInfo extends StatelessWidget {
  final StudyRoom room;

  const _RoomInfo({required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 8),
              Text('${room.building} · Floor ${room.floor}'),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.people, size: 16),
              const SizedBox(width: 8),
              Text('Capacity: ${room.capacity}'),
            ]),
            if (room.facilities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: room.facilities
                    .map((f) => Chip(label: Text(f)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
