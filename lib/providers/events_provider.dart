import 'package:flutter/foundation.dart';
import '../models/campus_event.dart';
import '../models/event_rsvp.dart';
import '../services/supabase_service.dart';

class EventsProvider extends ChangeNotifier {
  List<CampusEvent> _events = [];
  Map<String, EventRsvp> _myRsvps = {};
  bool _isLoading = false;

  List<CampusEvent> get events => _events;
  Map<String, EventRsvp> get myRsvps => _myRsvps;
  bool get isLoading => _isLoading;

  CampusEvent? get nextEvent {
    final now = DateTime.now();
    final upcoming = _events.where((e) => e.eventDate.isAfter(now)).toList();
    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  Future<void> fetchEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _events = await SupabaseService.fetchEvents();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyRsvps() async {
    try {
      final list = await SupabaseService.fetchMyRsvps();
      _myRsvps = {for (final r in list) r.eventId: r};
      notifyListeners();
    } catch (_) {}
  }

  Future<EventRsvp> rsvpToEvent(String eventId) async {
    final rsvp = await SupabaseService.createRsvp(eventId);
    _myRsvps[eventId] = rsvp;
    notifyListeners();
    return rsvp;
  }

  Future<void> cancelRsvp(String eventId) async {
    final rsvp = _myRsvps[eventId];
    if (rsvp == null) return;
    await SupabaseService.cancelRsvp(rsvp.id);
    _myRsvps.remove(eventId);
    notifyListeners();
  }

  Future<int> getRsvpCount(String eventId) async {
    return SupabaseService.getRsvpCount(eventId);
  }
}
