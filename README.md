# offline_sync_manager

A Flutter plugin for offline-first data synchronization with local storage, sync queue, conflict resolution, retries, and real-time event broadcasting.

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
