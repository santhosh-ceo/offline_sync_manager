import 'package:hive_flutter/hive_flutter.dart';
import 'package:offline_sync_manager/src/models/sync_operation.dart';

class HiveService {
  static const String dataBoxName = 'offline_data';
  static const String queueBoxName = 'sync_queue';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(dataBoxName);
    await Hive.openBox(queueBoxName);
  }

  Box get dataBox => Hive.box(dataBoxName);
  Box get queueBox => Hive.box(queueBoxName);

  Future<void> storeData(String collection, String key, Map<String, dynamic> data) async {
    await dataBox.put('$collection/$key', data);
  }

  Future<Map<String, dynamic>?> getData(String collection, String key) async {
    return dataBox.get('$collection/$key')?.cast<String, dynamic>();
  }

  Future<void> deleteData(String collection, String key) async {
    await dataBox.delete('$collection/$key');
  }

  Future<void> enqueueOperation(SyncOperation operation) async {
    await queueBox.put(operation.id, operation.toJson());
  }

  List<SyncOperation> getPendingOperations() {
    return queueBox.values
        .map((json) => SyncOperation.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> removeOperation(String operationId) async {
    await queueBox.delete(operationId);
  }
}