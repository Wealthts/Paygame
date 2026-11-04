import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/model/paygame_model.dart';

class GamePayController extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:3000';

  String? authToken;
  String currentRole = 'user'; // 'user' หรือ 'admin'
  int? currentUserId;
  bool isLoading = false;

  // Lists Data
  List<UserModel> users = [];
  List<GameModel> games = [];
  List<PackageModel> packages = [];
  List<OrderModel> orders = [];
  List<PaymentModel> payments = [];
  List<PointTransactionModel> pointHistory = [];
  ReceiptModel? currentReceipt;
  int userPointsBalance = 0;

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  // --- 1. AUTH & USER API ---
  Future<bool> login(String username, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        authToken = data['token'];
        // ตัวอย่างถอด Payload JWT เบื้องต้น
        if (username == 'Natthawat') {
          currentRole = 'admin';
        }
        isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login Error: $e');
    }
    isLoading = false;
    notifyListeners();
    return false;
  }

  // View All Users (Admin)
  Future<void> fetchAllUsers() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        users = data.map((e) => UserModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch Users Error: $e');
    }
  }

  // --- 2. GAMES API ---
  // View All Games
  Future<void> fetchGames() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/games'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        games = data.map((e) => GameModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch Games Error: $e');
    }
  }

  // Add Game (Admin)
  Future<bool> addGame(
    String name,
    String category,
    String uidPattern,
    bool requiresServer,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/games'),
        headers: headers,
        body: jsonEncode({
          'game_name': name,
          'category': category,
          'uid_pattern': uidPattern,
          'requires_server': requiresServer ? 1 : 0,
        }),
      );
      if (res.statusCode == 201) {
        fetchGames();
        return true;
      }
    } catch (e) {
      debugPrint('Add Game Error: $e');
    }
    return false;
  }

  // Update Game (Admin)
  Future<bool> updateGame(
    int gameId,
    String name,
    String category,
    String uidPattern,
    bool requiresServer,
    bool isActive,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/games/$gameId'),
        headers: headers,
        body: jsonEncode({
          'game_name': name,
          'category': category,
          'uid_pattern': uidPattern,
          'requires_server': requiresServer ? 1 : 0,
          'is_active': isActive ? 1 : 0,
        }),
      );
      if (res.statusCode == 200) {
        fetchGames();
        return true;
      }
    } catch (e) {
      debugPrint('Update Game Error: $e');
    }
    return false;
  }

  // --- 3. PACKAGES API ---
  // View All Package By Game
  Future<void> fetchPackagesByGame(int gameId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/packages/$gameId'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        packages = data.map((e) => PackageModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch Packages Error: $e');
    }
  }

  // Add Package (Admin)
  Future<bool> addPackage(int gameId, String name, double price) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/packages'),
        headers: headers,
        body: jsonEncode({
          'game_id': gameId,
          'package_name': name,
          'price': price,
        }),
      );
      if (res.statusCode == 201) {
        fetchPackagesByGame(gameId);
        return true;
      }
    } catch (e) {
      debugPrint('Add Package Error: $e');
    }
    return false;
  }

  // Update Package (Admin)
  Future<bool> updatePackage(
    int packageId,
    int gameId,
    String name,
    double price,
    bool isActive,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/packages/$packageId'),
        headers: headers,
        body: jsonEncode({
          'package_name': name,
          'price': price,
          'is_active': isActive ? 1 : 0,
        }),
      );
      if (res.statusCode == 200) {
        fetchPackagesByGame(gameId);
        return true;
      }
    } catch (e) {
      debugPrint('Update Package Error: $e');
    }
    return false;
  }

  // --- 4. ORDERS API ---
  // Add Order (User & Admin)
  Future<int?> createOrder(
    int packageId,
    String playerUid,
    String? serverCode,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: headers,
        body: jsonEncode({
          'package_id': packageId,
          'player_uid': playerUid,
          'server_code': serverCode ?? '',
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['order_id'];
      }
    } catch (e) {
      debugPrint('Create Order Error: $e');
    }
    return null;
  }

  // View All Orders / View Order By ID
  Future<void> fetchOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        orders = data.map((e) => OrderModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch Orders Error: $e');
    }
  }

  // --- 5. PAYMENTS API ---
  // Add Payment
  Future<bool> createPayment(int orderId, String method) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: headers,
        body: jsonEncode({'order_id': orderId, 'method': method}),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('Create Payment Error: $e');
      return false;
    }
  }

  // View All Payments & View Payment By ID
  Future<void> fetchPaymentById(int paymentId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        payments = [PaymentModel.fromJson(data)];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch Payment Error: $e');
    }
  }

  // Update Payment Status (Admin)
  Future<bool> updatePaymentStatus(int paymentId, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/payments/$paymentId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Update Payment Status Error: $e');
      return false;
    }
  }

  // --- 6. POINT TRANSACTIONS API ---
  // View Point Transaction Balance
  Future<void> fetchPointBalance() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/points/balance'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        userPointsBalance = data['total_points'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch Point Balance Error: $e');
    }
  }

  // View History Point Transaction
  Future<void> fetchPointHistory() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/points/history'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        pointHistory = data
            .map((e) => PointTransactionModel.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch Point History Error: $e');
    }
  }

  // Add Point Transaction (Admin)
  Future<bool> addPointTransaction(int userId, int orderId, int points) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/points/earn'),
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'order_id': orderId,
          'points': points,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('Add Point Transaction Error: $e');
      return false;
    }
  }

  // --- 7. RECEIPTS API ---
  // Create & View Receipt
  Future<void> fetchReceipt(int orderId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/receipts/$orderId'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        currentReceipt = ReceiptModel.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch Receipt Error: $e');
    }
  }
}
