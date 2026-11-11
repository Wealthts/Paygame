import 'package:frontend/models/paygame_models.dart';
import 'package:frontend/services/api_service.dart';

class PackageService {
  // Get all packages for Admin
  static Future<List<PackageModel>> getAdminPackages(String gameId) async {
    final response = await ApiService.get('/packages/admin/$gameId');

    List<dynamic> data;

    if (response is List) {
      data = response;
    } else if (response is Map && response['data'] is List) {
      data = response['data'];
    } else {
      throw Exception('Invalid packages response');
    }

    List<PackageModel> packages = [];

    for (var item in data) {
      packages.add(PackageModel.fromJson(Map<String, dynamic>.from(item)));
    }

    return packages;
  }

  // Get active packages for User
  static Future<List<PackageModel>> getActivePackages(String gameId) async {
    final response = await ApiService.get(
      '/packages/$gameId',
      requiresAuth: false,
    );

    List<dynamic> data;

    if (response is List) {
      data = response;
    } else {
      throw Exception('Invalid packages response');
    }

    List<PackageModel> packages = [];

    for (var item in data) {
      packages.add(PackageModel.fromJson(Map<String, dynamic>.from(item)));
    }

    return packages;
  }

  // Add package
  static Future<dynamic> addPackage(PackageModel package) async {
    return await ApiService.post('/packages', package.toJson());
  }

  // Update package
  static Future<dynamic> updatePackage(PackageModel package) async {
    return await ApiService.put(
      '/packages/${package.packageId}',
      package.toJson(),
    );
  }

  // Delete package (Soft Delete)
  static Future<dynamic> deletePackage(int packageId) async {
    return await ApiService.delete('/packages/$packageId');
  }
}
