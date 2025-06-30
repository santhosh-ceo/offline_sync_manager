import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:offline_sync_manager/src/models/sync_operation.dart';

class HttpService {
  final String baseUrl;
  final http.Client _client;

  HttpService(this.baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> syncOperation(SyncOperation operation) async {
    final url = Uri.parse('$baseUrl/${operation.collection}');
    final headers = {'Content-Type': 'application/json'};

    try {
      http.Response response;
      switch (operation.type) {
        case OperationType.create:
          response = await _client.post(
            url,
            headers: headers,
            body: jsonEncode(operation.data),
          );
          break;
        case OperationType.update:
          response = await _client.put(
            url,
            headers: headers,
            body: jsonEncode(operation.data),
          );
          break;
        case OperationType.delete:
          response = await _client.delete(
            Uri.parse('$url/${operation.data['id']}'),
            headers: headers,
          );
          break;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) ?? {};
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }
}