import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _firebaseData;
  String? _firebaseLatitude;
  String? _firebaseLongitude;
  String? _firebaseDate;
  String? _firebaseUtcTime;
  double? _latitude;
  double? _longitude;
  bool _loading = false;
  String? _error;
  Timer? _timer;
  late MapController _mapController;

  static const String _databaseUrl = 'https://location-app-764dd-default-rtdb.firebaseio.com/.json';
  static const String _latitudeUrl = 'https://location-app-764dd-default-rtdb.firebaseio.com/Latitude.json';
  static const String _longitudeUrl = 'https://location-app-764dd-default-rtdb.firebaseio.com/Longitude.json';
  static const String _dateUrl = 'https://location-app-764dd-default-rtdb.firebaseio.com/date.json';
  static const String _utcTimeUrl = 'https://location-app-764dd-default-rtdb.firebaseio.com/UTCTime.json';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchFirebaseData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Update data for both tabs every second
      _fetchFirebaseData(showLoading: false);
    });
  }

  Future<void> _fetchFirebaseData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      // Fetch specific latitude and longitude
      final latitudeResponse = await http.get(Uri.parse(_latitudeUrl));
      final longitudeResponse = await http.get(Uri.parse(_longitudeUrl));
      final dateResponse = await http.get(Uri.parse(_dateUrl));
      final utcTimeResponse = await http.get(Uri.parse(_utcTimeUrl));

      if (latitudeResponse.statusCode == 200) {
        final latitudeData = json.decode(utf8.decode(latitudeResponse.bodyBytes));
        setState(() {
          _firebaseLatitude = latitudeData?.toString();
          _latitude = double.tryParse(latitudeData?.toString() ?? '');
        });
      }

      if (longitudeResponse.statusCode == 200) {
        final longitudeData = json.decode(utf8.decode(longitudeResponse.bodyBytes));
        setState(() {
          _firebaseLongitude = longitudeData?.toString();
          _longitude = double.tryParse(longitudeData?.toString() ?? '');
        });
      }

      if (dateResponse.statusCode == 200) {
        final dateData = json.decode(utf8.decode(dateResponse.bodyBytes));
        setState(() {
          _firebaseDate = dateData?.toString();
        });
      }

      if (utcTimeResponse.statusCode == 200) {
        final utcTimeData = json.decode(utf8.decode(utcTimeResponse.bodyBytes));
        setState(() {
          _firebaseUtcTime = utcTimeData?.toString();
        });
      }

      // Always fetch all data for both tabs
      final response = await http.get(Uri.parse(_databaseUrl));
      if (response.statusCode == 200) {
        final dynamic parsed = json.decode(utf8.decode(response.bodyBytes));
        final String pretty = const JsonEncoder.withIndent('  ').convert(parsed);
    setState(() {
          _firebaseData = pretty;
        });
      }

      if (response.statusCode != 200) {
        setState(() {
          _error = 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Error'}';
        });
      }
    } catch (e) {
      if (showLoading) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _getSriLankaTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }

  String _getSriLankaDate() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('EEEE, MMMM dd, yyyy').format(now);
  }

  String _convertToSriLankaTime(String? utcTime, String? date) {
    if (utcTime == null) return 'N/A';
    
    try {
      String dateTimeString;
      
      if (date != null && date.isNotEmpty) {
        // We have both date and time
        if (date.contains('-') && utcTime.contains(':')) {
          dateTimeString = '$date $utcTime';
        } else if (date.contains(' ') && date.contains(':')) {
          dateTimeString = date;
        } else if (utcTime.contains(' ') && utcTime.contains('-')) {
          dateTimeString = utcTime;
        } else {
          dateTimeString = '$date $utcTime';
        }
      } else {
        // Only have UTC time, use current date
        final now = DateTime.now();
        final currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        dateTimeString = '$currentDate $utcTime';
      }
      
      // Parse the date and UTC time from Firebase
      final dateTime = DateTime.parse(dateTimeString);
      // Convert UTC to Sri Lanka time (UTC+5:30)
      final sriLankaTime = dateTime.toUtc().add(const Duration(hours: 5, minutes: 30));
      
      // Format as Sri Lanka time with timezone
      return DateFormat('yyyy-MM-dd HH:mm:ss (+05:30)').format(sriLankaTime);
    } catch (e) {
      // Return the raw values for debugging
      return 'Raw: $date $utcTime';
    }
  }

  void _recenterMap() {
    if (_latitude != null && _longitude != null) {
      _mapController.move(LatLng(_latitude!, _longitude!), 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Location App'),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _fetchFirebaseData(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_object),
            label: 'Data',
          ),
        ],
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildLocationPage();
      case 1:
        return _buildDataPage();
      default:
        return _buildLocationPage();
    }
  }

  Widget _buildLocationPage() {
    return Stack(
      children: [
        // Full screen map
        if (_latitude != null && _longitude != null)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_latitude!, _longitude!),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.location_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_latitude!, _longitude!),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        
        // Overlay with coordinates and controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.deepPurple,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location (${_firebaseLatitude ?? 'N/A'}, ${_firebaseLongitude ?? 'N/A'})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const Spacer(),
                    if (_loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_firebaseUtcTime != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Last Updated (SL Time): ${_convertToSriLankaTime(_firebaseUtcTime, _firebaseDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Debug info - remove this later
                  // Text(
                  //   'Debug - Date: ${_firebaseDate ?? 'null'}, Time: ${_firebaseUtcTime ?? 'null'}',
                  //   style: const TextStyle(
                  //     fontSize: 10,
                  //     color: Colors.red,
                  //   ),
                  // ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : () => _fetchFirebaseData(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Auto-refresh: Both tabs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // No data message (only shown when no coordinates)
        if (_firebaseLatitude == null && _firebaseLongitude == null)
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Location Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make sure your Firebase has /Latitude and /Longitude paths',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : () => _fetchFirebaseData(),
                    icon: _loading ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ) : const Icon(Icons.refresh),
                    label: Text(_loading ? 'Loading...' : 'Refresh Data'),
                  ),
                ],
              ),
            ),
          ),
        
        // Floating action button to re-center map
        if (_latitude != null && _longitude != null)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _recenterMap,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              child: const Icon(Icons.my_location),
              tooltip: 'Re-center to current location',
            ),
          ),
      ],
    );
  }

  Widget _buildDataPage() {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Error Loading Data',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _fetchFirebaseData(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : _firebaseData == null
                ? const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.data_object, color: Colors.deepPurple),
                              const SizedBox(width: 8),
            Text(
                                'Firebase Realtime Database',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              _firebaseData!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
