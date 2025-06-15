class WeatherModel {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final String description;
  final String iconCode;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final double visibility;
  final int uvIndex;
  final DateTime sunrise;
  final DateTime sunset;
  final double lat;
  final double lon;

  WeatherModel({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    required this.lat,
    required this.lon,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? 'Unknown',
      country: json['sys']?['country'] ?? '',
      temperature: (json['main']['temp'] ?? 0).toDouble(),
      feelsLike: (json['main']['feels_like'] ?? 0).toDouble(),
      description: json['weather'][0]['description'] ?? 'No description',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      pressure: json['main']['pressure'] ?? 0,
      visibility: (json['visibility'] ?? 0).toDouble() / 1000, // Convert to km
      uvIndex: 0, // UV index not available in current weather API
      sunrise: DateTime.fromMillisecondsSinceEpoch((json['sys']['sunrise'] ?? 0) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch((json['sys']['sunset'] ?? 0) * 1000),
      lat: (json['coord']?['lat'] ?? 0).toDouble(),
      lon: (json['coord']?['lon'] ?? 0).toDouble(),
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  String get formattedLocation => country.isNotEmpty ? '$cityName, $country' : cityName;

  String get windSpeedText => '${windSpeed.toStringAsFixed(1)} m/s';

  String get visibilityText => '${visibility.toStringAsFixed(1)} km';

  String get pressureText => '$pressure hPa';

  String get humidityText => '$humidity%';

  String get temperatureText => '${temperature.toStringAsFixed(0)}°C';

  String get feelsLikeText => 'Feels like ${feelsLike.toStringAsFixed(0)}°C';
}

class HourlyForecast {
  final DateTime dateTime;
  final double temperature;
  final String description;
  final String iconCode;
  final int humidity;
  final double windSpeed;
  final double precipitation;

  HourlyForecast({
    required this.dateTime,
    required this.temperature,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] ?? 0).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      precipitation: (json['pop'] ?? 0).toDouble() * 100, // Probability of precipitation
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  String get temperatureText => '${temperature.toStringAsFixed(0)}°C';
  String get timeText => '${dateTime.hour}:00';
  String get precipitationText => '${precipitation.toStringAsFixed(0)}%';
}

class ForecastDay {
  final DateTime date;
  final List<HourlyForecast> hourlyForecasts;

  ForecastDay({
    required this.date,
    required this.hourlyForecasts,
  });

  double get maxTemperature => hourlyForecasts.isEmpty ? 0 :
  hourlyForecasts.map((h) => h.temperature).reduce((a, b) => a > b ? a : b);

  double get minTemperature => hourlyForecasts.isEmpty ? 0 :
  hourlyForecasts.map((h) => h.temperature).reduce((a, b) => a < b ? a : b);

  String get mainDescription => hourlyForecasts.isEmpty ? '' :
  hourlyForecasts[hourlyForecasts.length ~/ 2].description;

  String get mainIconCode => hourlyForecasts.isEmpty ? '01d' :
  hourlyForecasts[hourlyForecasts.length ~/ 2].iconCode;

  String get dateText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return 'Today';
    } else if (compareDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$mainIconCode@2x.png';
  String get temperatureRangeText => '${maxTemperature.toStringAsFixed(0)}°/${minTemperature.toStringAsFixed(0)}°';
}

class WeatherAlert {
  final String title;
  final String description;
  final String severity;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> tags;

  WeatherAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.startTime,
    required this.endTime,
    required this.tags,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      title: json['event'] ?? 'Weather Alert',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'minor',
      startTime: DateTime.fromMillisecondsSinceEpoch(json['start'] * 1000),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['end'] * 1000),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  String get severityColor {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return 'red';
      case 'severe':
        return 'orange';
      case 'moderate':
        return 'yellow';
      default:
        return 'blue';
    }
  }
}