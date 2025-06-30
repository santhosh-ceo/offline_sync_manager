import 'package:uuid/uuid.dart';

enum OperationType { create, update, delete }

class SyncOperation {
  final String id;
  final OperationType type;
  final String collection;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;

  SyncOperation({
    String? id,
    required this.type,
    required this.collection,
    required this.data,
    DateTime? timestamp,
    this.retryCount = 0,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'collection': collection,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    id: json['id'],
    type: OperationType.values.firstWhere((e) => e.toString() == json['type']),
    collection: json['collection'],
    data: Map<String, dynamic>.from(json['data']),
    timestamp: DateTime.parse(json['timestamp']),
    retryCount: json['retryCount'],
  );
}