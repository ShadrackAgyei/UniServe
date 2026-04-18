import 'package:flutter/material.dart';

import 'time_of_day_utils.dart';

class StudyRoomBooking {
  final String id;
  final String roomId;
  final String userId;
  final DateTime bookingDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String qrToken;
  final bool checkedIn;

  StudyRoomBooking({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.qrToken,
    required this.checkedIn,
  });

  factory StudyRoomBooking.fromSupabase(Map<String, dynamic> json) {
    return StudyRoomBooking(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      startTime: parseTimeOfDay(json['start_time'] as String),
      endTime: parseTimeOfDay(json['end_time'] as String),
      qrToken: json['qr_token'] as String,
      checkedIn: json['checked_in'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSupabase() => {
        'room_id': roomId,
        'user_id': userId,
        'booking_date':
            '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}',
        'start_time': formatTimeOfDay(startTime),
        'end_time': formatTimeOfDay(endTime),
      };
}
