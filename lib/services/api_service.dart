import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class ApiService {
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data, {
    String token = '',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> get(
    String path, {
    String token = '',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> data, {
    String token = '',
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    String token = '',
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }
}