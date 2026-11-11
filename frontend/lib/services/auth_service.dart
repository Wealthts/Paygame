import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class AuthService {
  // Login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await ApiService.post('/login', {
        'username': username,
        'password': password,
      }, requiresAuth: false);

      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid login response');
      }

      final token = response['token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Login token not found');
      }

      // Save JWT token
      await ApiService.saveToken(token);

      // Verify saved token
      final savedToken = await ApiService.getToken();

      if (savedToken != token) {
        await ApiService.deleteToken();
        throw Exception('Failed to save authentication token');
      }

      debugPrint('JWT Token Saved: true');

      return response;
    } catch (e) {
      // Remove token if login process fails
      await ApiService.deleteToken();
      rethrow;
    }
  }

  // Register
  static Future<dynamic> register({
    required String username,
    required String displayName,
    required String email,
    required String password,
  }) async {
    return await ApiService.post('/register', {
      'username': username,
      'display_name': displayName,
      'email': email,
      'password': password,
    }, requiresAuth: false);
  }

  // Logout
  static Future<void> logout() async {
    await ApiService.deleteToken();

    // Verify token deletion
    final token = await ApiService.getToken();

    if (token != null) {
      throw Exception('Failed to remove authentication token');
    }

    debugPrint('JWT Token Removed');
  }
}
