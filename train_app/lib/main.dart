import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  String? _firebaseDate;
  String? _firebaseUtcTime;
  bool _loading = false;
  String? _error;

  static const String _databaseUrl = 'https://location-app-764dd-default-rtdb.firebaseio.com/.json';
  static const String _dateUrl = 'https://location-app-764dd-default-rtdb.firebaseio.com/date.json';
  static const String _utcTimeUrl = 'https://location-app-764dd-default-rtdb.firebaseio.com/UTCTime.json';

  @override
  void initState() {
    super.initState();
    _fetchFirebaseData();
  }

  Future<void> _fetchFirebaseData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch all data
      final response = await http.get(Uri.parse(_databaseUrl));
      if (response.statusCode == 200) {
        final dynamic parsed = json.decode(utf8.decode(response.bodyBytes));
        final String pretty = const JsonEncoder.withIndent('  ').convert(parsed);
        setState(() {
          _firebaseData = pretty;
        });
      }

      // Fetch specific date and UTCTime
      final dateResponse = await http.get(Uri.parse(_dateUrl));
      final utcTimeResponse = await http.get(Uri.parse(_utcTimeUrl));

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

      if (response.statusCode != 200) {
        setState(() {
          _error = 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Error'}';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Location App'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _fetchFirebaseData,
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
            icon: Icon(Icons.access_time),
            label: 'Time',
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
        return _buildTimePage();
      case 1:
        return _buildDataPage();
      default:
        return _buildTimePage();
    }
  }

  Widget _buildTimePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.access_time,
            size: 80,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 20),
          Text(
            'Firebase Date & Time',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 30),
          if (_firebaseDate != null) ...[
            const Text(
              'Date from Firebase:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Text(
                _firebaseDate!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_firebaseUtcTime != null) ...[
            const Text(
              'UTC Time from Firebase:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Text(
                _firebaseUtcTime!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (_firebaseDate == null && _firebaseUtcTime == null) ...[
            const SizedBox(height: 20),
            const Text(
              'No date/time data found in Firebase',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              'Make sure your Firebase has /date and /UTCTime paths',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loading ? null : _fetchFirebaseData,
            icon: _loading ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : const Icon(Icons.refresh),
            label: Text(_loading ? 'Loading...' : 'Refresh Data'),
          ),
        ],
      ),
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
                        onPressed: _fetchFirebaseData,
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