# offline_sync_manager

A Flutter plugin for offline-first data synchronization with local storage, sync queue, conflict resolution, retries, and real-time event broadcasting.


[![Pub Version](https://img.shields.io/pub/v/offline_sync_manager)](https://pub.dev/packages/offline_sync_manager)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features
- **Local Storage**: Uses Hive for lightweight, fast local storage.
- **Remote Sync**: Syncs data with a RESTful API.
- **Sync Queue**: Queues operations when offline and processes them when online.
- **Conflict Resolution**: Uses last-write-wins strategy based on timestamps.
- **Retries**: Automatically retries failed operations with exponential backoff.
- **Event Broadcasting**: Emits real-time sync status updates via streams.

## Installation
Add this to your `pubspec.yaml`:
```yaml
dependencies:
  offline_sync_manager: ^0.0.1
```
## Usage
Initialize the manager:
```
final syncManager = await OfflineSyncManager.initialize(
  baseUrl: 'https://api.example.com',
);
```
Perform CRUD operations:
```
// Create
await syncManager.create(
  collection: 'notes',
  data: {'id': '1', 'title': 'Test Note', 'content': 'Test'},
);

// Update
await syncManager.update(
  collection: 'notes',
  data: {'id': '1', 'title': 'Updated Note', 'content': 'Updated'},
);

// Delete
await syncManager.delete(collection: 'notes', id: '1');

// Read
final data = await syncManager.read('notes', '1');
```
Listen to sync events:
```
syncManager.syncEvents.listen((event) {
  print('Status: ${event.status}, Message: ${event.message}');
});
```
## Server Requirements
The plugin expects a RESTful API with:
`POST /:collection` - Create
`PUT /:collection` - Update
`DELETE /:collection/:id` - Delete
Responses must include a `timestamp` field.

## Contributing
Contributions are welcome! Please open an issue or PR on GitHub.

### Notes
- **Quality**: The code is modular, type-safe, and follows Dart/Flutter best practices. It includes error handling, retries, and conflict resolution.
- **Extensibility**: You can extend the plugin by adding support for other databases (e.g., Drift) or sync protocols (e.g., WebSocket).
- **Testing**: Add unit tests in `test/` for production use. I can provide test code if needed.
- **Premium Support**: As a premium user, let me know if you need additional features, optimizations, or help setting up the server.

If you encounter issues or need further customization, please provide details, and I’ll assist promptly!

## Acknowledgements
#### Built with ❤️ by Santhosh Adiga U


