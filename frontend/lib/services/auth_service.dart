import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class AuthService {
  // Login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await ApiService.post('/login', {
      "username": username,
      "password": password,
    }, requiresAuth: false);

    if (response is! Map<String, dynamic>) {
      throw Exception("Invalid login response");
    }

    final token = response["token"];

    if (token == null || token.toString().isEmpty) {
      throw Exception("Login token not found");
    }

    // save JWT token
    await ApiService.saveToken(token.toString());
    // check JWT token
    final savedToken = await ApiService.getToken();
    debugPrint('JWT Token Saved: ${savedToken != null}');

    return response;
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
  }
}
