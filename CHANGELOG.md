# Changelog

## 0.0.1

- Initial release of `offline_sync_manager`.
- Features:
    - Offline-first data storage using Hive.
    - Remote synchronization with RESTful API.
    - Sync queue for offline operations.
    - Conflict resolution with last-write-wins strategy.
    - Automatic retries with exponential backoff.
    - Real-time event broadcasting via streams.
- Example weather app included in `example/`.