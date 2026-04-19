import 'package:flutter/foundation.dart';
import '../models/class_entry.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class ScheduleProvider extends ChangeNotifier {
  List<ClassEntry> _entries = [];
  bool _isLoading = false;

  List<ClassEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  List<ClassEntry> entriesForDay(int day) {
    final list = _entries.where((e) => e.dayOfWeek == day).toList();
    list.sort((a, b) {
      final aMin = a.startTime.hour * 60 + a.startTime.minute;
      final bMin = b.startTime.hour * 60 + b.startTime.minute;
      return aMin.compareTo(bMin);
    });
    return list;
  }

  ClassEntry? get nextClassToday {
    final now = DateTime.now();
    final todayDay = now.weekday - 1; // 0=Mon
    final todayEntries = entriesForDay(todayDay);
    final nowMinutes = now.hour * 60 + now.minute;
    for (final e in todayEntries) {
      final startMin = e.startTime.hour * 60 + e.startTime.minute;
      if (startMin > nowMinutes) return e;
    }
    return null;
  }

  Future<void> fetchEntries() async {
    _isLoading = true;
    notifyListeners();
    try {
      _entries = await SupabaseService.fetchClassSchedule();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(ClassEntry entry) async {
    final created = await SupabaseService.insertClassEntry(entry);
    try {
      await NotificationService.scheduleClassReminder(created);
    } catch (_) {}
    await fetchEntries();
  }

  Future<void> deleteEntry(String id) async {
    await SupabaseService.deleteClassEntry(id);
    try {
      await NotificationService.cancelClassReminder(id);
    } catch (_) {}
    await fetchEntries();
  }
}
