import 'package:frontend/services/api_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>> create({
    required int orderId,
    required String method,
  }) async {
    final response = await ApiService.post('/payments', {
      'order_id': orderId,
      'method': method,
    });
    if (response is! Map) throw Exception('Invalid payment response');
    return Map<String, dynamic>.from(response);
  }

  static Future<List<Map<String, dynamic>>> listForAdmin() async {
    final response = await ApiService.get('/payments');
    if (response is! List) throw Exception('Invalid payments response');
    return response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<void> updateStatus(int paymentId, String status) async {
    await ApiService.put('/payments/$paymentId/status', {'status': status});
  }
}
