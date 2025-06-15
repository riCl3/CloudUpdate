import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import '../core/constants.dart';

class WeatherApi {
  String get _apiKey => dotenv.env['API_KEY'] ?? '';

  // Get current location weather
  Future<WeatherModel?> fetchCurrentLocationWeather() async {
    try {
      Position position = await _getCurrentPosition();
      return await fetchWeatherByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Failed to get current location weather: $e');
    }
  }

  // Fetch current weather by city name
  Future<WeatherModel?> fetchWeather(String city) async {
    try {
      final url = '${Constants.baseUrl}?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      return _handleCurrentWeatherResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch weather for $city: $e');
    }
  }

  // Fetch current weather by coordinates
  Future<WeatherModel?> fetchWeatherByCoordinates(double lat, double lon) async {
    try {
      final url = '${Constants.baseUrl}?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      return _handleCurrentWeatherResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch weather by coordinates: $e');
    }
  }

  // Fetch 5-day weather forecast
  Future<List<ForecastDay>> fetchForecast(String city) async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/forecast?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      return _handleForecastResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch forecast for $city: $e');
    }
  }

  // Fetch 5-day forecast by coordinates
  Future<List<ForecastDay>> fetchForecastByCoordinates(double lat, double lon) async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      return _handleForecastResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch forecast by coordinates: $e');
    }
  }

  // Fetch weather alerts
  Future<List<WeatherAlert>> fetchWeatherAlerts(double lat, double lon) async {
    try {
      final url = 'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      return _handleAlertsResponse(response);
    } catch (e) {
      // Return empty list if alerts API fails (might need different subscription)
      return [];
    }
  }

  // Get multiple cities weather
  Future<List<WeatherModel>> fetchMultipleCitiesWeather(List<String> cities) async {
    try {
      final List<WeatherModel> weatherList = [];

      for (String city in cities) {
        try {
          final weather = await fetchWeather(city);
          if (weather != null) {
            weatherList.add(weather);
          }
        } catch (e) {
          // Continue with other cities if one fails
          print('Failed to fetch weather for $city: $e');
        }
      }

      return weatherList;
    } catch (e) {
      throw Exception('Failed to fetch weather for multiple cities: $e');
    }
  }

  // Handle current weather response
  WeatherModel? _handleCurrentWeatherResponse(http.Response response) {
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return WeatherModel.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      throw Exception('City not found');
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key');
    } else {
      throw Exception('Failed to fetch weather: ${response.statusCode}');
    }
  }

  // Handle forecast response
  List<ForecastDay> _handleForecastResponse(http.Response response) {
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> forecastList = jsonData['list'] ?? [];

      // Group forecast by days
      Map<String, List<HourlyForecast>> groupedForecast = {};

      for (var item in forecastList) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        final dateKey = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

        final hourlyForecast = HourlyForecast.fromJson(item);

        if (groupedForecast.containsKey(dateKey)) {
          groupedForecast[dateKey]!.add(hourlyForecast);
        } else {
          groupedForecast[dateKey] = [hourlyForecast];
        }
      }

      // Convert to ForecastDay objects
      return groupedForecast.entries.map((entry) {
        return ForecastDay(
          date: DateTime.parse(entry.key),
          hourlyForecasts: entry.value,
        );
      }).toList();

    } else {
      throw Exception('Failed to fetch forecast: ${response.statusCode}');
    }
  }

  // Handle alerts response
  List<WeatherAlert> _handleAlertsResponse(http.Response response) {
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> alertsList = jsonData['alerts'] ?? [];

      return alertsList.map((alert) => WeatherAlert.fromJson(alert)).toList();
    } else {
      return [];
    }
  }

  // Get current position
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Check if location services are available
  Future<bool> isLocationServiceAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }
}