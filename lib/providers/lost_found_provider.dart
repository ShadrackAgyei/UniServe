import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/lost_found_item.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

class LostFoundProvider extends ChangeNotifier {
  final DatabaseService _cache = DatabaseService();
  List<LostFoundItem> _items = [];
  bool _isLoading = false;
  String _filter = 'all'; // 'all', 'lost', 'found'
  String _searchQuery = '';

  List<LostFoundItem> get items {
    var filtered = _items;
    if (_filter != 'all') {
      filtered = filtered.where((i) => i.type == _filter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((i) =>
        i.title.toLowerCase().contains(query) ||
        i.description.toLowerCase().contains(query) ||
        i.location.toLowerCase().contains(query)
      ).toList();
    }
    return filtered;
  }

  bool get isLoading => _isLoading;
  String get filter => _filter;
  String get searchQuery => _searchQuery;

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await SupabaseService.getLostFoundItems();
      await _cache.cacheLostFoundItems(_items);
    } catch (_) {
      _items = await _cache.getCachedLostFoundItems();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem({
    required String title,
    required String description,
    required String type,
    required String location,
    required String contactInfo,
    String? imagePath,
  }) async {
    await SupabaseService.insertLostFoundItem(
      title: title,
      description: description,
      type: type,
      location: location,
      contactInfo: contactInfo,
      imageFile: imagePath != null ? File(imagePath) : null,
    );
    await loadItems();
  }

  Future<void> resolveItem(int id) async {
    await SupabaseService.resolveLostFoundItem(id);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await SupabaseService.deleteLostFoundItem(id);
    await loadItems();
  }
}
