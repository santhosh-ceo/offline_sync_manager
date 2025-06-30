import 'package:offline_sync_manager/src/models/sync_operation.dart';

enum SyncStatus { pending, syncing, success, failed }

class SyncEvent {
  final SyncStatus status;
  final String? message;
  final SyncOperation? operation;

  SyncEvent(this.status, {this.message, this.operation});
}
