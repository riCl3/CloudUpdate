import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class CityComparisonCard extends StatelessWidget {
  final WeatherModel weather;
  final VoidCallback onRemove;

  const CityComparisonCard({
    super.key,
    required this.weather,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blue.withOpacity(0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Weather icon
              Image.network(
                weather.iconUrl,
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.cloud,
                  size: 50,
                  color: Colors.grey[400],
                ),
              ),

              const SizedBox(width: 16),

              // City info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.formattedLocation,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildQuickInfo(Icons.thermostat, weather.temperatureText),
                        const SizedBox(width: 16),
                        _buildQuickInfo(Icons.water_drop, weather.humidityText),
                        const SizedBox(width: 16),
                        _buildQuickInfo(Icons.air, weather.windSpeedText),
                      ],
                    ),
                  ],
                ),
              ),

              // Temperature
              Column(
                children: [
                  Text(
                    weather.temperatureText,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    weather.feelsLikeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // Remove button
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
                color: Colors.red[400],
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}