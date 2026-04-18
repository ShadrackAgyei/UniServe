import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const _hapticsKey = 'haptics_enabled';

  bool _hapticsEnabled = true;

  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticsEnabled = prefs.getBool(_hapticsKey) ?? true;
    notifyListeners();
  }

  Future<void> setHapticsEnabled(bool value) async {
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, value);
  }
}
