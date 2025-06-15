import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/weather_api.dart';
import '../models/weather_model.dart';
import '../widgets/weather_card.dart';
import '../widgets/forecast_card.dart';
import '../widgets/hourly_forecast_card.dart';
import '../widgets/city_comparison_card.dart';
import '../widgets/weather_alerts_card.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final WeatherApi _api = WeatherApi();
  late TabController _tabController;

  WeatherModel? _currentWeather;
  List<ForecastDay> _forecast = [];
  List<WeatherAlert> _alerts = [];
  List<WeatherModel> _savedCities = [];
  bool _isLoading = false;
  bool _isLocationEnabled = false;
  String? _currentCity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeWeather();
    _loadSavedCities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeWeather() async {
    setState(() => _isLoading = true);

    try {
      // Check if location is available
      _isLocationEnabled = await _api.isLocationServiceAvailable();

      if (_isLocationEnabled) {
        await _loadCurrentLocationWeather();
      } else {
        // Load default city weather
        await _searchWeather('London');
      }
    } catch (e) {
      await _searchWeather('London');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadCurrentLocationWeather() async {
    try {
      final weather = await _api.fetchCurrentLocationWeather();
      if (weather != null) {
        setState(() {
          _currentWeather = weather;
          _currentCity = weather.cityName;
        });
        await _loadForecast();
        await _loadAlerts();
      }
    } catch (e) {
      _showError('Failed to get current location weather: $e');
    }
  }

  Future<void> _searchWeather([String? city]) async {
    final searchCity = city ?? _controller.text.trim();
    if (searchCity.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final weather = await _api.fetchWeather(searchCity);
      if (weather != null) {
        setState(() {
          _currentWeather = weather;
          _currentCity = weather.cityName;
        });
        await _loadForecast();
        await _loadAlerts();
        _controller.clear();
      }
    } catch (e) {
      _showError('Failed to fetch weather: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadForecast() async {
    if (_currentWeather == null) return;

    try {
      final forecast = await _api.fetchForecast(_currentWeather!.cityName);
      setState(() => _forecast = forecast);
    } catch (e) {
      print('Failed to load forecast: $e');
    }
  }

  Future<void> _loadAlerts() async {
    if (_currentWeather == null) return;

    try {
      final alerts = await _api.fetchWeatherAlerts(
        _currentWeather!.lat,
        _currentWeather!.lon,
      );
      setState(() => _alerts = alerts);
    } catch (e) {
      print('Failed to load alerts: $e');
    }
  }

  Future<void> _addCityToComparison() async {
    if (_currentWeather == null) return;

    final exists = _savedCities.any((city) =>
    city.cityName.toLowerCase() == _currentWeather!.cityName.toLowerCase());

    if (!exists) {
      setState(() {
        _savedCities.add(_currentWeather!);
      });
      await _saveCitiesToPrefs();
      _showSnackBar('${_currentWeather!.cityName} added to comparison');
    } else {
      _showSnackBar('${_currentWeather!.cityName} is already in comparison');
    }
  }

  Future<void> _removeCityFromComparison(WeatherModel weather) async {
    setState(() {
      _savedCities.removeWhere((city) => city.cityName == weather.cityName);
    });
    await _saveCitiesToPrefs();
    _showSnackBar('${weather.cityName} removed from comparison');
  }

  Future<void> _refreshComparisonCities() async {
    if (_savedCities.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final cityNames = _savedCities.map((city) => city.cityName).toList();
      final updatedCities = await _api.fetchMultipleCitiesWeather(cityNames);
      setState(() => _savedCities = updatedCities);
    } catch (e) {
      _showError('Failed to refresh cities: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadSavedCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCityNames = prefs.getStringList('saved_cities') ?? [];

      if (savedCityNames.isNotEmpty) {
        final cities = await _api.fetchMultipleCitiesWeather(savedCityNames);
        setState(() => _savedCities = cities);
      }
    } catch (e) {
      print('Failed to load saved cities: $e');
    }
  }

  Future<void> _saveCitiesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityNames = _savedCities.map((city) => city.cityName).toList();
      await prefs.setStringList('saved_cities', cityNames);
    } catch (e) {
      print('Failed to save cities: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C2C2C), // Dark grey
              Color(0xFF4A4A4A), // Medium grey
              Color(0xFF6B6B6B), // Light grey
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchWeather(),
                        decoration: InputDecoration(
                          hintText: "Enter city name",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.95),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isLocationEnabled)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: IconButton(
                          onPressed: _loadCurrentLocationWeather,
                          icon: const Icon(Icons.my_location, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
                  tabs: const [
                    Tab(text: 'Current'),
                    Tab(text: 'Forecast'),
                    Tab(text: 'Compare'),
                    Tab(text: 'Alerts'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCurrentWeatherTab(),
                    _buildForecastTab(),
                    _buildComparisonTab(),
                    _buildAlertsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherTab() {
    if (_currentWeather == null) {
      return const Center(
        child: Text(
          "Search for a city to view weather",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          WeatherCard(weather: _currentWeather!),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _addCityToComparison,
              icon: const Icon(Icons.add, color: Colors.grey),
              label: const Text('Add to Comparison', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTab() {
    if (_forecast.isEmpty) {
      return const Center(
        child: Text(
          "No forecast data available",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 5-day forecast
          ...(_forecast.take(5).map((day) => ForecastCard(forecastDay: day))),

          // Hourly forecast for today
          if (_forecast.isNotEmpty && _forecast.first.hourlyForecasts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Today\'s Hourly Forecast',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            HourlyForecastCard(hourlyForecasts: _forecast.first.hourlyForecasts),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'City Comparison',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _refreshComparisonCities,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _savedCities.isEmpty
              ? const Center(
            child: Text(
              "No cities added for comparison\nAdd cities from the Current tab",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _savedCities.length,
            itemBuilder: (context, index) {
              return CityComparisonCard(
                weather: _savedCities[index],
                onRemove: () => _removeCityFromComparison(_savedCities[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _alerts.isEmpty
          ? const Center(
        child: Text(
          "No weather alerts available",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
        ),
      )
          : ListView.builder(
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          return WeatherAlertsCard(alert: _alerts[index]);
        },
      ),
    );
  }
}