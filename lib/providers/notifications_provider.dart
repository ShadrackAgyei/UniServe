import 'package:flutter/foundation.dart';
import '../models/campus_notification.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

class NotificationsProvider extends ChangeNotifier {
  final DatabaseService _cache = DatabaseService();
  List<CampusNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<CampusNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await SupabaseService.getNotifications();
      await _cache.cacheNotifications(_notifications);
    } catch (_) {
      _notifications = await _cache.getCachedNotifications();
    }
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    // Mark locally immediately for responsiveness
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = CampusNotification(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        category: _notifications[index].category,
        createdAt: _notifications[index].createdAt,
        isRead: true,
      );
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }
}
