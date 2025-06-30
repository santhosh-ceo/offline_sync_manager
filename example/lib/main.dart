import 'package:flutter/material.dart';
import 'package:offline_sync_manager/offline_sync_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('todo_ids'); // Track todo IDs
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late OfflineSyncManager syncManager;
  bool _isInitialized = false;
  String _syncStatus = 'Initializing...';
  String _errorMessage = '';
  bool _isOnline = true;
  final TextEditingController _titleController = TextEditingController();
  List<Map<String, dynamic>> _todos = [];
  final Box _todoIdsBox = Hive.box('todo_ids');

  @override
  void initState() {
    super.initState();
    _initializeSyncManager();
  }

  Future<void> _initializeSyncManager() async {
    syncManager = await OfflineSyncManager.initialize(
      baseUrl: 'https://jsonplaceholder.typicode.com',
    );
    syncManager.syncEvents.listen((event) {
      setState(() {
        _syncStatus = 'Sync: ${event.status} - ${event.message ?? ''}';
      });
      _loadTodos();
    });
    setState(() {
      _isInitialized = true;
    });
    // Initialize todo IDs from Hive
    _todoIdsBox.values.forEach((id) {
      if (!_todoIdsBox.containsKey(id)) {
        _todoIdsBox.put(id, id);
      }
    });
    await _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = <Map<String, dynamic>>[];
    for (final id in _todoIdsBox.values) {
      final todo = await syncManager.read('todos', id.toString());
      if (todo != null) todos.add(todo);
    }
    setState(() {
      _todos = todos;
    });
  }

  bool _validateInput() {
    if (_titleController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Todo title is required.';
      });
      return false;
    }
    setState(() {
      _errorMessage = '';
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Todo Sync App'),
          centerTitle: true,
        ),
        body: _isInitialized
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _syncStatus,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Todo Title'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_validateInput()) {
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    await syncManager.create(
                      collection: 'todos',
                      data: {
                        'id': id,
                        'title': _titleController.text,
                        'completed': false,
                        'userId': 1, // Required by JSONPlaceholder
                        'timestamp': DateTime.now().toIso8601String(),
                      },
                    );
                    await _todoIdsBox.put(id, id);
                    _titleController.clear();
                    await _loadTodos();
                  }
                },
                child: const Text('Add Todo'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Simulate Online: '),
                  Switch(
                    value: _isOnline,
                    onChanged: (value) async {
                      setState(() {
                        _isOnline = value;
                      });
                      syncManager.setOnlineStatus(_isOnline);
                      if (_isOnline) {
                        await syncManager.syncService.sync();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _todos.length,
                  itemBuilder: (context, index) {
                    final todo = _todos[index];
                    return ListTile(
                      title: Text(todo['title']),
                      leading: Checkbox(
                        value: todo['completed'],
                        onChanged: (value) async {
                          await syncManager.update(
                            collection: 'todos',
                            data: {
                              'id': todo['id'],
                              'title': todo['title'],
                              'completed': value ?? false,
                              'userId': 1,
                              'timestamp': DateTime.now().toIso8601String(),
                            },
                          );
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await syncManager.delete(
                            collection: 'todos',
                            id: todo['id'],
                          );
                          await _todoIdsBox.delete(todo['id']);
                          await _loadTodos();
                        },
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
    _titleController.dispose();
    super.dispose();
  }
}