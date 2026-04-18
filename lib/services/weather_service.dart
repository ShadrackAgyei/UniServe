import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String description;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String icon;
  final String cityName;

  WeatherData({
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.icon,
    required this.cityName,
  });
}

class WeatherService {
  // Using wttr.in - free, no API key needed
  Future<WeatherData> getWeather({double? lat, double? lon}) async {
    try {
      // Default to Accra, Ghana (near Ashesi University)
      final location = (lat != null && lon != null) ? '$lat,$lon' : 'Accra';
      final url = Uri.parse('https://wttr.in/$location?format=j1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];
        final area = data['nearest_area'][0];

        return WeatherData(
          description: current['weatherDesc'][0]['value'] as String,
          temperature: double.parse(current['temp_C'] as String),
          feelsLike: double.parse(current['FeelsLikeC'] as String),
          humidity: int.parse(current['humidity'] as String),
          icon: _mapWeatherIcon(current['weatherCode'] as String),
          cityName: area['areaName'][0]['value'] as String,
        );
      }
      throw Exception('Failed to load weather');
    } catch (e) {
      throw Exception('Weather unavailable: $e');
    }
  }

  String _mapWeatherIcon(String code) {
    final c = int.tryParse(code) ?? 0;
    if (c == 113) return '☀️';
    if (c == 116) return '⛅';
    if (c <= 122) return '☁️';
    if (c <= 299) return '🌧️';
    if (c <= 399) return '🌨️';
    return '🌤️';
  }
}
