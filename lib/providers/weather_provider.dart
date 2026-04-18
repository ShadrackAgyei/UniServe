import 'package:flutter/foundation.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weather;
  bool _isLoading = false;
  String? _error;

  WeatherData? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWeather({double? lat, double? lon}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _weather = await _weatherService.getWeather(lat: lat, lon: lon);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
