import 'package:flutter/material.dart';
import 'package:offline_sync_manager/offline_sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late OfflineSyncManager syncManager;
  bool _isInitialized = false;
  String _status = 'Initializing...';

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
        _status = 'Status: ${event.status} - ${event.message ?? ''}';
      });
    });
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Offline Sync Manager Demo')),
        body: _isInitialized
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_status),
              ElevatedButton(
                onPressed: () async {
                  await syncManager.create(
                    collection: 'notes',
                    data: {
                      'id': '1',
                      'title': 'Test Note',
                      'content': 'This is a test note.',
                    },
                  );
                },
                child: const Text('Create Note'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await syncManager.update(
                    collection: 'notes',
                    data: {
                      'id': '1',
                      'title': 'Updated Note',
                      'content': 'This is an updated note.',
                    },
                  );
                },
                child: const Text('Update Note'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await syncManager.delete(
                    collection: 'notes',
                    id: '1',
                  );
                },
                child: const Text('Delete Note'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final data = await syncManager.read('notes', '1');
                  setState(() {
                    _status = 'Read: ${data?.toString() ?? 'No data'}';
                  });
                },
                child: const Text('Read Note'),
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
    super.dispose();
  }
}