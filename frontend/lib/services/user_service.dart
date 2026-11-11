import 'package:frontend/services/api_service.dart';

/// One row of the `users` table, as returned by GET /api/users.
class UserModel {
  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: (json['user_id'] as num).toInt(),
    username: json['username']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    displayName: json['display_name']?.toString() ?? '',
    role: json['role']?.toString() ?? 'user',
    isActive: json['is_active'] == true || json['is_active'] == 1,
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
        DateTime.now(),
  );

  final int userId;
  final String username;
  final String email;
  final String displayName;
  String role; // 'admin' | 'user'
  bool isActive;
  final DateTime createdAt;

  /// First letter for the avatar.
  String get initial {
    final name = displayName.isNotEmpty ? displayName : username;
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}

/// Admin-only user management API.
class UserService {
  static Future<List<UserModel>> list() async {
    final response = await ApiService.get('/users');
    if (response is! Map || response['users'] is! List) {
      throw Exception('Invalid users response');
    }
    return (response['users'] as List)
        .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> makeAdmin(int userId) =>
      ApiService.put('/users/$userId/role', {'role': 'admin'});

  static Future<void> setActive(int userId, bool isActive) =>
      ApiService.put('/users/$userId/status', {'is_active': isActive});

  static Future<void> setPassword(int userId, String password) =>
      ApiService.put('/users/$userId/password', {'password': password});
}
