import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  /// Auth bypassed — kept for legacy [AuthProvider] compatibility.
  Future<bool> login(String email, String password) async => true;

  Future<List<dynamic>> fetchEntries() async {
    final response = await http.get(Uri.parse('$baseUrl/posts'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load entries');
    }
  }

  Future<void> createEntry(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'title': payload['title']?.toString() ?? '',
        'body': payload['bodyText']?.toString() ?? payload['body']?.toString() ?? '',
        'userId': 1,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create entry');
    }
  }

  Future<void> deleteEntry(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/posts/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete entry');
    }
  }
}
