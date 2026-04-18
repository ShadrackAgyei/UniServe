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
}
