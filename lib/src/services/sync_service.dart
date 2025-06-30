import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:offline_sync_manager/src/models/sync_operation.dart';
import 'package:offline_sync_manager/src/models/sync_status.dart';
import 'package:offline_sync_manager/src/services/connectivity_service.dart';
import 'package:offline_sync_manager/src/services/hive_service.dart';
import 'package:offline_sync_manager/src/services/http_service.dart';

class SyncService {
  final HiveService hiveService;
  final HttpService httpService;
  final ConnectivityService connectivityService;
  final StreamController<SyncEvent> _eventController =
      StreamController.broadcast();
  Timer? _retryTimer;
  bool _isSyncing = false;
  bool _isOnline = true;

  SyncService({
    required this.hiveService,
    required this.httpService,
    required this.connectivityService,
  });

  Stream<SyncEvent> get syncEvents => _eventController.stream;

  Future<void> enqueueOperation(SyncOperation operation) async {
    await hiveService.enqueueOperation(operation);
    _eventController.add(SyncEvent(SyncStatus.pending, operation: operation));
    if (!_isSyncing) {
      await sync();
    }
  }

  Future<void> sync() async {
    if (_isSyncing || !(_isOnline && await connectivityService.isOnline())) {
      return;
    }

    _isSyncing = true;
    final operations = hiveService.getPendingOperations();

    for (var operation in operations) {
      if (operation.retryCount >= 3) {
        _eventController.add(
          SyncEvent(
            SyncStatus.failed,
            message: 'Max retries reached for operation ${operation.id}',
            operation: operation,
          ),
        );
        await hiveService.removeOperation(operation.id);
        continue;
      }

      _eventController.add(SyncEvent(SyncStatus.syncing, operation: operation));

      try {
        final serverData = await httpService.syncOperation(operation);
        await _applyOperation(operation, serverData);
        await hiveService.removeOperation(operation.id);
        _eventController.add(
          SyncEvent(SyncStatus.success, operation: operation),
        );
      } catch (e) {
        operation.retryCount++;
        await hiveService.enqueueOperation(operation);
        _eventController.add(
          SyncEvent(
            SyncStatus.failed,
            message: 'Sync failed: $e',
            operation: operation,
          ),
        );
        _scheduleRetry();
      }
    }

    _isSyncing = false;
  }

  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
  }

  Future<void> _applyOperation(
    SyncOperation operation,
    Map<String, dynamic> serverData,
  ) async {
    final key = operation.data['id'].toString();
    final collection = operation.collection;

    switch (operation.type) {
      case OperationType.create:
      case OperationType.update:
        // Conflict resolution: last-write-wins
        final localData = await hiveService.getData(collection, key);
        final serverTimestamp = DateTime.parse(
          serverData['timestamp'] ?? operation.timestamp.toIso8601String(),
        );
        if (localData != null && localData['timestamp'] != null) {
          final localTimestamp = DateTime.parse(localData['timestamp']);
          if (localTimestamp.isAfter(serverTimestamp)) {
            // Local data is newer, skip update
            return;
          }
        }
        await hiveService.storeData(collection, key, serverData);
        break;
      case OperationType.delete:
        await hiveService.deleteData(collection, key);
        break;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(
      Duration(
        seconds:
            pow(2, hiveService.getPendingOperations().first.retryCount).toInt(),
      ),
      () {
        sync();
      },
    );
  }

  void startAutoSync() {
    connectivityService.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.mobile)) {
        sync();
      }
    });
  }

  void dispose() {
    _retryTimer?.cancel();
    _eventController.close();
  }
}
