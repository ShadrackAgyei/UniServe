import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _legacyLocalProfilePhotoKey = 'local_profile_photo';
  UserProfile? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String? _localProfilePhoto;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => SupabaseService.currentSession != null && _user != null;
  bool get isInitialized => _isInitialized;
  String? get localProfilePhoto => _localProfilePhoto;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyLocalProfilePhotoKey);

    // Check for existing Supabase session
    if (SupabaseService.currentSession != null) {
      try {
        _user = await SupabaseService.getProfile();
        await _loadLocalProfilePhoto();
      } catch (_) {
        // Offline — try cached profile
        final userJson = prefs.getString('user_json');
        if (userJson != null) {
          try {
            _user = UserProfile.fromJson(
              json.decode(userJson) as Map<String, dynamic>,
            );
            await _loadLocalProfilePhoto();
          } catch (_) {}
        }
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  void setLocalProfilePhoto(String path) {
    _localProfilePhoto = path;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      final userId = _user?.id;
      if (userId != null) {
        prefs.setString(_localProfilePhotoKey(userId), path);
      }
    });
  }

  Future<bool> register({
    required String studentId,
    required String name,
    required String email,
    required String password,
    String? phone,
    String? department,
    String? program,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await SupabaseService.signUp(
        email: email,
        password: password,
        studentId: studentId,
        name: name,
        phone: phone,
        department: department,
        program: program,
      );
      await _loadLocalProfilePhoto();
      await _cacheProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await SupabaseService.signIn(
        email: email,
        password: password,
      );
      await _loadLocalProfilePhoto();
      await _cacheProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? department,
    String? program,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await SupabaseService.updateProfile(
        name: name,
        phone: phone,
        department: department,
        program: program,
      );
      await _cacheProfile();
    } catch (_) {
      // Offline fallback: update local copy
      _user = _user?.copyWith(
        name: name,
        phone: phone,
        department: department,
        program: program,
      );
      await _cacheProfile();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      _user = await SupabaseService.getProfile();
      await _cacheProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await SupabaseService.signOut();
    } catch (_) {}
    _user = null;
    _localProfilePhoto = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_json');
    await prefs.remove(_legacyLocalProfilePhotoKey);
    notifyListeners();
  }

  Future<void> _cacheProfile() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_json', json.encode(_user!.toJson()));
  }

  Future<void> _loadLocalProfilePhoto() async {
    final userId = _user?.id;
    if (userId == null) {
      _localProfilePhoto = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _localProfilePhoto = prefs.getString(_localProfilePhotoKey(userId));
  }

  String _localProfilePhotoKey(String userId) => 'local_profile_photo_$userId';
}
