import 'package:offline_sync_manager/src/models/sync_operation.dart';
import 'package:offline_sync_manager/src/models/sync_status.dart';
import 'package:offline_sync_manager/src/services/connectivity_service.dart';
import 'package:offline_sync_manager/src/services/hive_service.dart';
import 'package:offline_sync_manager/src/services/http_service.dart';
import 'package:offline_sync_manager/src/services/sync_service.dart';

class OfflineSyncManager {
  late final HiveService _hiveService;
  late final SyncService _syncService;

  OfflineSyncManager._();

  static Future<OfflineSyncManager> initialize({
    required String baseUrl,
  }) async {
    final manager = OfflineSyncManager._();
    manager._hiveService = HiveService();
    await manager._hiveService.init();
    final httpService = HttpService(baseUrl);
    final connectivityService = ConnectivityService();
    manager._syncService = SyncService(
      hiveService: manager._hiveService,
      httpService: httpService,
      connectivityService: connectivityService,
    );
    manager._syncService.startAutoSync();
    return manager;
  }

  Future<void> create({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final operation = SyncOperation(
      type: OperationType.create,
      collection: collection,
      data: {...data, 'timestamp': DateTime.now().toIso8601String()},
    );
    await _hiveService.storeData(
      collection,
      data['id'].toString(),
      operation.data,
    );
    await _syncService.enqueueOperation(operation);
  }

  Future<void> update({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final operation = SyncOperation(
      type: OperationType.update,
      collection: collection,
      data: {...data, 'timestamp': DateTime.now().toIso8601String()},
    );
    await _hiveService.storeData(
      collection,
      data['id'].toString(),
      operation.data,
    );
    await _syncService.enqueueOperation(operation);
  }

  Future<void> delete({required String collection, required String id}) async {
    final operation = SyncOperation(
      type: OperationType.delete,
      collection: collection,
      data: {'id': id, 'timestamp': DateTime.now().toIso8601String()},
    );
    await _hiveService.deleteData(collection, id);
    await _syncService.enqueueOperation(operation);
  }

  Future<Map<String, dynamic>?> read(String collection, String id) async {
    return _hiveService.getData(collection, id);
  }

  Stream<SyncEvent> get syncEvents => _syncService.syncEvents;

  void dispose() {
    _syncService.dispose();
  }
}
