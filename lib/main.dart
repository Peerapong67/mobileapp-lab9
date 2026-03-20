import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkyCast',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
      ),
      home: const WeatherPage(),
    );
  }
}

// ========== Model ==========

class CityResult {
  final String name;
  final String country;
  final String? admin1;
  final double lat;
  final double lon;

  CityResult({
    required this.name,
    required this.country,
    this.admin1,
    required this.lat,
    required this.lon,
  });

  factory CityResult.fromJson(Map<String, dynamic> json) {
    return CityResult(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      admin1: json['admin1'],
      lat: (json['latitude'] as num).toDouble(),
      lon: (json['longitude'] as num).toDouble(),
    );
  }

  String get displayName => admin1 != null ? '$name, $admin1, $country' : '$name, $country';
}

class WeatherData {
  final double temperature;
  final double windspeed;
  final int weatherCode;
  final String time;

  WeatherData({
    required this.temperature,
    required this.windspeed,
    required this.weatherCode,
    required this.time,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final cw = json['current_weather'];
    return WeatherData(
      temperature: (cw['temperature'] as num).toDouble(),
      windspeed: (cw['windspeed'] as num).toDouble(),
      weatherCode: cw['weathercode'] as int,
      time: cw['time'] ?? '',
    );
  }

  String get weatherDescription {
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode <= 3) return 'Partly Cloudy';
    if (weatherCode <= 9) return 'Foggy';
    if (weatherCode <= 19) return 'Drizzle';
    if (weatherCode <= 29) return 'Thunderstorm';
    if (weatherCode <= 39) return 'Sandstorm';
    if (weatherCode <= 49) return 'Fog';
    if (weatherCode <= 59) return 'Drizzle';
    if (weatherCode <= 69) return 'Rain';
    if (weatherCode <= 79) return 'Snow';
    if (weatherCode <= 84) return 'Rain Showers';
    if (weatherCode <= 94) return 'Thunderstorm';
    return 'Unknown';
  }

  IconData get weatherIcon {
    if (weatherCode == 0) return Icons.wb_sunny;
    if (weatherCode <= 3) return Icons.cloud;
    if (weatherCode <= 49) return Icons.foggy;
    if (weatherCode <= 69) return Icons.grain;
    if (weatherCode <= 79) return Icons.ac_unit;
    if (weatherCode <= 84) return Icons.umbrella;
    return Icons.thunderstorm;
  }

  Color get tempColor {
    if (temperature >= 35) return Colors.red;
    if (temperature >= 28) return Colors.orange;
    if (temperature >= 20) return Colors.amber;
    if (temperature >= 10) return Colors.lightBlue;
    return Colors.blue;
  }
}

// ========== API Service ==========

class WeatherService {
  // ค้นหาเมืองจาก Open-Meteo Geocoding API
  static Future<List<CityResult>> searchCity(String query) async {
    final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=10&language=en&format=json');
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>? ?? [];
      return results.map((e) => CityResult.fromJson(e)).toList();
    }
    return [];
  }

  // ดึงข้อมูลอากาศจาก Open-Meteo Forecast API
  static Future<WeatherData> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&windspeed_unit=kmh');
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return WeatherData.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to fetch weather: ${response.statusCode}');
  }
}

// ========== Weather Page ==========

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  List<CityResult> _searchResults = [];
  CityResult? _selectedCity;
  WeatherData? _weatherData;

  bool _loadingSearch = false;
  bool _loadingWeather = false;
  String _errorMessage = '';

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // โหลดเมืองเริ่มต้น
    _loadDefaultCity();
  }

  Future<void> _loadDefaultCity() async {
    final results = await WeatherService.searchCity('Chiang Mai');
    if (results.isNotEmpty) {
      _selectCity(results.first);
    }
  }

  Future<void> _searchCities(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _loadingSearch = true);
    try {
      final results = await WeatherService.searchCity(query);
      setState(() {
        _searchResults = results;
        _loadingSearch = false;
      });
    } catch (e) {
      setState(() {
        _loadingSearch = false;
        _errorMessage = 'Search failed. Check internet connection.';
      });
    }
  }

  Future<void> _selectCity(CityResult city) async {
    setState(() {
      _selectedCity = city;
      _searchResults = [];
      _searchController.clear();
      _loadingWeather = true;
      _errorMessage = '';
    });

    try {
      final weather = await WeatherService.fetchWeather(city.lat, city.lon);
      setState(() {
        _weatherData = weather;
        _loadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _loadingWeather = false;
        _errorMessage = 'Failed to fetch weather data.';
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('SkyCast',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFBF360C), Color(0xFFFF6D00), Color(0xFFFFCC80)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ---- Search Bar ----
                _buildSearchBar(),
                const SizedBox(height: 8),

                // ---- Search Results Dropdown ----
                if (_searchResults.isNotEmpty) _buildSearchResults(),
                if (_loadingSearch)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                const SizedBox(height: 24),

                // ---- Weather Card ----
                if (_loadingWeather)
                  const CircularProgressIndicator(color: Colors.white)
                else if (_errorMessage.isNotEmpty)
                  _buildErrorCard()
                else if (_weatherData != null && _selectedCity != null)
                  _buildWeatherCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Search Bar Widget ----
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search city worldwide...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (val) {
          setState(() {});
          _searchCities(val);
        },
      ),
    );
  }

  // ---- Search Results Widget ----
  Widget _buildSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFBF360C).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) => Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
        itemBuilder: (context, index) {
          final city = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: Colors.orangeAccent),
            title: Text(city.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(city.displayName,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            onTap: () => _selectCity(city),
          );
        },
      ),
    );
  }

  // ---- Weather Card Widget ----
  Widget _buildWeatherCard() {
    final weather = _weatherData!;
    final city = _selectedCity!;

    return Column(
      children: [
        // ไอคอนอากาศหมุน
        RotationTransition(
          turns: _animController,
          child: Icon(weather.weatherIcon, size: 90, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(weather.weatherDescription,
            style: const TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.2)),
        const SizedBox(height: 24),

        // Card หลัก
        Card(
          elevation: 16,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          color: Colors.white.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // ชื่อเมือง
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 18),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        city.displayName,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // อุณหภูมิ
                Text(
                  '${weather.temperature}°C',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: weather.tempColor,
                  ),
                ),

                const Divider(color: Colors.white30, height: 32),

                // Wind speed
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.air, color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Text('Wind: ${weather.windspeed} km/h',
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),

                // Coordinates
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.my_location, color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Lat: ${city.lat.toStringAsFixed(2)}, Lon: ${city.lon.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Refresh Button
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => _selectCity(_selectedCity!),
          icon: const Icon(Icons.refresh, color: Colors.white70),
          label: const Text('Refresh', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  // ---- Error Card Widget ----
  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_errorMessage,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}