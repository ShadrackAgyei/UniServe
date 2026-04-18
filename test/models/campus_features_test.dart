import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniserve/models/class_entry.dart';
import 'package:uniserve/models/campus_event.dart';
import 'package:uniserve/models/study_room.dart';
import 'package:uniserve/models/study_room_booking.dart';
import 'package:uniserve/models/event_rsvp.dart';

void main() {
  group('ClassEntry', () {
    final json = {
      'id': 'abc-123',
      'user_id': 'user-1',
      'course_name': 'Algorithms',
      'course_code': 'CS301',
      'room': 'A101',
      'day_of_week': 0,
      'start_time': '09:00:00',
      'end_time': '11:00:00',
      'lecturer': 'Dr. Smith',
      'color_hex': '#4A90E2',
    };

    test('fromSupabase parses correctly', () {
      final e = ClassEntry.fromSupabase(json);
      expect(e.id, 'abc-123');
      expect(e.courseName, 'Algorithms');
      expect(e.dayOfWeek, 0);
      expect(e.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(e.endTime, const TimeOfDay(hour: 11, minute: 0));
      expect(e.colorHex, '#4A90E2');
    });

    test('toSupabase serialises time as HH:MM:SS', () {
      final e = ClassEntry.fromSupabase(json);
      final map = e.toSupabase();
      expect(map['start_time'], '09:00:00');
      expect(map['end_time'], '11:00:00');
      expect(map['day_of_week'], 0);
    });
  });

  group('CampusEvent', () {
    final json = {
      'id': 'ev-1',
      'title': 'Hackathon',
      'description': 'Annual hackathon',
      'event_date': '2026-05-01',
      'start_time': '08:00:00',
      'end_time': '20:00:00',
      'location': 'Engineering Block',
      'category': 'Academic',
      'image_url': null,
      'capacity': 100,
      'organizer': 'CS Dept',
      'created_at': '2026-04-01T00:00:00.000Z',
    };

    test('fromSupabase parses correctly', () {
      final e = CampusEvent.fromSupabase(json);
      expect(e.title, 'Hackathon');
      expect(e.eventDate, DateTime(2026, 5, 1));
      expect(e.startTime, const TimeOfDay(hour: 8, minute: 0));
      expect(e.capacity, 100);
    });
  });

  group('StudyRoom', () {
    final json = {
      'id': 'room-1',
      'name': 'Library Room 3',
      'building': 'Library',
      'floor': 2,
      'capacity': 8,
      'facilities': ['whiteboard', 'projector'],
      'image_url': null,
    };

    test('fromSupabase parses correctly', () {
      final r = StudyRoom.fromSupabase(json);
      expect(r.name, 'Library Room 3');
      expect(r.facilities, ['whiteboard', 'projector']);
      expect(r.capacity, 8);
    });
  });

  group('StudyRoomBooking', () {
    final json = {
      'id': 'bk-1',
      'room_id': 'room-1',
      'user_id': 'user-1',
      'booking_date': '2026-05-02',
      'start_time': '10:00:00',
      'end_time': '11:00:00',
      'qr_token': 'token-xyz',
      'checked_in': false,
    };

    test('fromSupabase parses correctly', () {
      final b = StudyRoomBooking.fromSupabase(json);
      expect(b.qrToken, 'token-xyz');
      expect(b.startTime, const TimeOfDay(hour: 10, minute: 0));
      expect(b.checkedIn, false);
    });
  });

  group('EventRsvp', () {
    final json = {
      'id': 'rsvp-1',
      'event_id': 'ev-1',
      'user_id': 'user-1',
      'qr_token': 'tok-abc',
      'checked_in': false,
    };

    test('fromSupabase parses correctly', () {
      final r = EventRsvp.fromSupabase(json);
      expect(r.qrToken, 'tok-abc');
      expect(r.eventId, 'ev-1');
    });
  });
}
