import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/study_room_booking.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final StudyRoomBooking booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, MMMM d').format(booking.bookingDate);
    final startStr = booking.startTime.format(context);
    final endStr = booking.endTime.format(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('Booking Confirmed',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(dateStr,
                  style: Theme.of(context).textTheme.bodyLarge),
              Text('$startStr – $endStr',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              QrImageView(
                data: booking.qrToken,
                version: QrVersions.auto,
                size: 200,
              ),
              const SizedBox(height: 16),
              Text(
                'Scan this QR code at the room entrance',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Open QR Scanner'),
                onPressed: () => context.push('/campus/qr-scanner'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/campus'),
                child: const Text('Back to Campus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
