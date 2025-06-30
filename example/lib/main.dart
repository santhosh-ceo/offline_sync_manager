import 'package:flutter/material.dart';
import 'package:offline_sync_manager/offline_sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherApp());
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  late OfflineSyncManager syncManager;
  bool _isInitialized = false;
  String _syncStatus = 'Initializing...';
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  List<Map<String, dynamic>> _weatherData = [];

  @override
  void initState() {
    super.initState();
    _initializeSyncManager();
  }

  Future<void> _initializeSyncManager() async {
    syncManager = await OfflineSyncManager.initialize(
      baseUrl: 'https://api.example.com', // Replace with your server URL
    );
    syncManager.syncEvents.listen((event) {
      setState(() {
        _syncStatus = 'Sync: ${event.status} - ${event.message ?? ''}';
      });
      _loadWeatherData();
    });
    setState(() {
      _isInitialized = true;
    });
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    // Simulate reading all weather data from Hive
    final box = syncManager.read;
    final data = <Map<String, dynamic>>[];
    // Note: Hive doesn't provide a direct way to list all keys, so assume IDs are known or stored separately
    // For simplicity, we'll use a predefined list of IDs or extend the plugin to store keys
    for (var i = 1; i <= 10; i++) {
      final item = await box('weather', i.toString());
      if (item != null) data.add(item);
    }
    setState(() {
      _weatherData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Weather Sync App'),
          centerTitle: true,
        ),
        body: _isInitialized
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_syncStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: _tempController,
                decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _conditionController,
                decoration: const InputDecoration(labelText: 'Condition'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  await syncManager.create(
                    collection: 'weather',
                    data: {
                      'id': id,
                      'city': _cityController.text,
                      'temperature': double.parse(_tempController.text),
                      'condition': _conditionController.text,
                    },
                  );
                  _cityController.clear();
                  _tempController.clear();
                  _conditionController.clear();
                },
                child: const Text('Add Weather'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _weatherData.length,
                  itemBuilder: (context, index) {
                    final data = _weatherData[index];
                    return ListTile(
                      title: Text('${data['city']} - ${data['condition']}'),
                      subtitle: Text('Temp: ${data['temperature']}°C'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              await syncManager.update(
                                collection: 'weather',
                                data: {
                                  'id': data['id'],
                                  'city': data['city'],
                                  'temperature': data['temperature'] + 1.0,
                                  'condition': 'Updated',
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await syncManager.delete(
                                collection: 'weather',
                                id: data['id'],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  @override
  void dispose() {
    syncManager.dispose();
    _cityController.dispose();
    _tempController.dispose();
    _conditionController.dispose();
    super.dispose();
  }
}