import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // API Base URL
  // For Windows / Web:
  static const String baseUrl = 'http://localhost:3000/api';

  // Secure Storage
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  // Get JWT Token
  static Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  // Save JWT Token
  static Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  // Delete JWT Token
  static Future<void> deleteToken() async {
    await storage.delete(key: 'auth_token');
  }

  // Create Headers
  static Future<Map<String, String>> getHeaders({
    bool requiresAuth = true,
  }) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (requiresAuth) {
      String? token = await getToken();

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle API Response
  static dynamic handleResponse(http.Response response) {
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (e) {
      data = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception('API Error ${response.statusCode}: $data');
  }

  // GET Request
  static Future<dynamic> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await getHeaders(requiresAuth: requiresAuth),
    );

    return handleResponse(response);
  }

  // POST Request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await getHeaders(requiresAuth: requiresAuth),
      body: jsonEncode(body),
    );

    return handleResponse(response);
  }

  // PUT Request
  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await getHeaders(requiresAuth: requiresAuth),
      body: jsonEncode(body),
    );

    return handleResponse(response);
  }

  // DELETE Request
  static Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await getHeaders(requiresAuth: requiresAuth),
    );

    return handleResponse(response);
  }
}
