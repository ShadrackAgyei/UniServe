import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/study_room_booking.dart';
import '../../../providers/study_rooms_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<StudyRoomsProvider>();
      p.fetchMyBookings();
      if (p.rooms.isEmpty) p.fetchRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFB0311E);
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: brand,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<StudyRoomsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();
          final bookings = List<StudyRoomBooking>.from(provider.myBookings)
            ..sort((a, b) {
              final aStart = DateTime(a.bookingDate.year, a.bookingDate.month,
                  a.bookingDate.day, a.startTime.hour, a.startTime.minute);
              final bStart = DateTime(b.bookingDate.year, b.bookingDate.month,
                  b.bookingDate.day, b.startTime.hour, b.startTime.minute);
              return aStart.compareTo(bStart);
            });

          final upcoming = bookings.where((b) {
            final end = DateTime(b.bookingDate.year, b.bookingDate.month,
                b.bookingDate.day, b.endTime.hour, b.endTime.minute);
            return end.isAfter(now);
          }).toList();

          final past = bookings.where((b) {
            final end = DateTime(b.bookingDate.year, b.bookingDate.month,
                b.bookingDate.day, b.endTime.hour, b.endTime.minute);
            return !end.isAfter(now);
          }).toList();

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.meeting_room_outlined,
                      size: 48, color: brand.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('No bookings yet'),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionLabel('UPCOMING', isDark),
                const SizedBox(height: 8),
                ...upcoming.map((b) => _BookingCard(
                      booking: b,
                      roomName: provider.roomNameFor(b.roomId),
                      isDark: isDark,
                    )),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionLabel('PAST', isDark),
                const SizedBox(height: 8),
                ...past.map((b) => _BookingCard(
                      booking: b,
                      roomName: provider.roomNameFor(b.roomId),
                      isDark: isDark,
                      isPast: true,
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.35),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final StudyRoomBooking booking;
  final String roomName;
  final bool isDark;
  final bool isPast;

  const _BookingCard({
    required this.booking,
    required this.roomName,
    required this.isDark,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFB0311E);
    final dateStr = DateFormat('EEEE, MMMM d').format(booking.bookingDate);
    final startStr = booking.startTime.format(context);
    final endStr = booking.endTime.format(context);

    final bg = Color.fromRGBO(176, 49, 30, isDark ? 0.06 : 0.04);
    final border = Color.fromRGBO(176, 49, 30, isDark ? 0.18 : 0.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Color.fromRGBO(176, 49, 30, isPast ? 0.12 : 0.28),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.meeting_room_outlined,
                size: 20,
                color: isPast ? brand.withValues(alpha: 0.5) : Colors.white),
          ),
          title: Text(
            roomName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isPast
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4))
                  : (isDark
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF111111)),
            ),
          ),
          subtitle: Text(
            '$dateStr · $startStr–$endStr',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : const Color(0xFF666666),
            ),
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Show this QR code at the room entrance',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: booking.qrToken,
                  version: QrVersions.auto,
                  size: 180,
                ),
              ),
            ),
            if (booking.checkedIn) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text('Checked in',
                      style: TextStyle(
                          color: Colors.green.shade700, fontSize: 13)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
