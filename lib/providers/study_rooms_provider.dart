import 'package:flutter/material.dart';
import '../models/study_room.dart';
import '../models/study_room_booking.dart';
import '../services/supabase_service.dart';

class StudyRoomsProvider extends ChangeNotifier {
  List<StudyRoom> _rooms = [];
  List<StudyRoomBooking> _myBookings = [];
  bool _isLoading = false;

  List<StudyRoom> get rooms => _rooms;
  List<StudyRoomBooking> get myBookings => _myBookings;
  bool get isLoading => _isLoading;

  StudyRoomBooking? get nextBooking {
    final now = DateTime.now();
    final upcoming = _myBookings.where((b) {
      final end = DateTime(
        b.bookingDate.year, b.bookingDate.month, b.bookingDate.day,
        b.endTime.hour, b.endTime.minute,
      );
      return end.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final aStart = DateTime(a.bookingDate.year, a.bookingDate.month,
            a.bookingDate.day, a.startTime.hour, a.startTime.minute);
        final bStart = DateTime(b.bookingDate.year, b.bookingDate.month,
            b.bookingDate.day, b.startTime.hour, b.startTime.minute);
        return aStart.compareTo(bStart);
      });
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> fetchRooms() async {
    _isLoading = true;
    notifyListeners();
    try {
      _rooms = await SupabaseService.fetchStudyRooms();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyBookings() async {
    try {
      _myBookings = await SupabaseService.fetchMyBookings();
      notifyListeners();
    } catch (_) {}
  }

  Future<List<StudyRoomBooking>> getBookingsForRoom(
    String roomId,
    DateTime date,
  ) async {
    return SupabaseService.fetchRoomBookings(roomId, date);
  }

  Future<StudyRoomBooking> createBooking({
    required String roomId,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    final booking = await SupabaseService.createRoomBooking(
      roomId: roomId,
      date: date,
      start: start,
      end: end,
    );
    await fetchMyBookings();
    return booking;
  }

  Future<void> cancelBooking(String id) async {
    await SupabaseService.cancelRoomBooking(id);
    await fetchMyBookings();
  }

  String roomNameFor(String roomId) {
    try {
      return _rooms.firstWhere((r) => r.id == roomId).name;
    } catch (_) {
      return 'Room';
    }
  }
}
