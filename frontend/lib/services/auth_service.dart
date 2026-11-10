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
    return response;
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String displayName,
  }) async {
    final response = await ApiService.post('/register', {
      "username": username,
      "password": password,
      "email": email,
      "display name": displayName,
    }, requiresAuth: false);

    if (response is! Map<String, dynamic>) {
      throw Exception("Invalid register response");
    }
    return response;
  }

  // Logout
  static Future<void> logout() async {
    await ApiService.deleteToken();
  }
}
