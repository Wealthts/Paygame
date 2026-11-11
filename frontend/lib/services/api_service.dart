import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Override for a phone or a deployed server, e.g.
  // --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  // Request Timeout
  static const Duration timeoutDuration = Duration(seconds: 15);
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
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();

      if (token != null && token.isNotEmpty) {
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

    if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    }

    if (response.statusCode == 403) {
      throw Exception('Access denied: You do not have permission');
    }

    throw Exception('API Error ${response.statusCode}: $data');
  }

  // Send HTTP Request
  static Future<dynamic> sendRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(timeoutDuration);

      return handleResponse(response);
    } on TimeoutException {
      throw Exception('Connection timeout. Please try again.');
    } on http.ClientException {
      throw Exception(
        'Cannot connect to server. Please check your connection.',
      );
    }
  }

  // GET Request
  static Future<dynamic> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final headers = await getHeaders(requiresAuth: requiresAuth);

    return await sendRequest(
      () => http.get(Uri.parse('$baseUrl$endpoint'), headers: headers),
    );
  }

  // POST Request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final headers = await getHeaders(requiresAuth: requiresAuth);

    return await sendRequest(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  // PUT Request
  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final headers = await getHeaders(requiresAuth: requiresAuth);

    return await sendRequest(
      () => http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  // DELETE Request
  static Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final headers = await getHeaders(requiresAuth: requiresAuth);

    return await sendRequest(
      () => http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers),
    );
  }
}
