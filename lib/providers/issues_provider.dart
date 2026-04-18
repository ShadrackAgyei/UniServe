import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/campus_issue.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

class IssuesProvider extends ChangeNotifier {
  final DatabaseService _cache = DatabaseService();
  List<CampusIssue> _issues = [];
  bool _isLoading = false;

  List<CampusIssue> get issues => _issues;
  List<CampusIssue> get activeIssues =>
      _issues.where((i) => i.status != 'Resolved').toList();
  List<CampusIssue> get resolvedIssues =>
      _issues.where((i) => i.status == 'Resolved').toList();
  bool get isLoading => _isLoading;

  Future<void> loadIssues() async {
    _isLoading = true;
    notifyListeners();
    try {
      _issues = await SupabaseService.getIssues();
      await _cache.cacheIssues(_issues);
    } catch (_) {
      _issues = await _cache.getCachedIssues();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addIssue({
    required String title,
    required String description,
    required String category,
    String? imagePath,
  }) async {
    await SupabaseService.insertIssue(
      title: title,
      description: description,
      category: category,
      imageFile: imagePath != null ? File(imagePath) : null,
    );
    await loadIssues();
  }

  Future<void> updateStatus(int id, String status) async {
    await SupabaseService.updateIssueStatus(id, status);
    await loadIssues();
  }

  Future<void> deleteIssue(int id) async {
    await SupabaseService.deleteIssue(id);
    await loadIssues();
  }
}
