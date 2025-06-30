import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:offline_sync_manager/src/models/sync_operation.dart';

class HttpService {
  final String baseUrl;

  HttpService(this.baseUrl);

  Future<Map<String, dynamic>> syncOperation(SyncOperation operation) async {
    final url = Uri.parse('$baseUrl/${operation.collection}');
    final headers = {'Content-Type': 'application/json'};

    try {
      http.Response response;
      switch (operation.type) {
        case OperationType.create:
          response = await http.post(
            url,
            headers: headers,
            body: jsonEncode(operation.data),
          );
          break;
        case OperationType.update:
          response = await http.put(
            url,
            headers: headers,
            body: jsonEncode(operation.data),
          );
          break;
        case OperationType.delete:
          response = await http.delete(
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
