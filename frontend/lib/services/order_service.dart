import 'package:frontend/services/api_service.dart';

class OrderService {
  static Future<Map<String, dynamic>> create({
    required int packageId,
    required String playerUid,
    String? serverCode,
    int? couponId,
    bool useCoins = false,
    String method = 'qr',
  }) async {
    final response = await ApiService.post('/checkout', {
      'package_id': packageId,
      'coupon_id': couponId,
      'use_coins': useCoins,
      'method': method,
      'player_uid': playerUid,
      'server_code': serverCode ?? '',
    });

    if (response is! Map) {
      throw Exception('Invalid order response');
    }
    return Map<String, dynamic>.from(response);
  }

  static Future<List<Map<String, dynamic>>> list() async {
    final response = await ApiService.get('/orders');
    if (response is! List) throw Exception('Invalid orders response');
    return response
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
