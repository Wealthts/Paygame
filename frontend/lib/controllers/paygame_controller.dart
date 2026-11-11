import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:frontend/models/paygame_models.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/game_service.dart';

class PaygameController extends ChangeNotifier {
  PaygameController() {
    loadCatalog();
  }

  String? authToken;
  String currentRole = 'user';
  String currentUsername = '';
  int? currentUserId;
  String currentDisplayName = '';
  int userPointsBalance = 0;
  String? walletError;

  OrderModel? latestOrder;
  final List<CouponModel> _coupons = [];
  final Set<String> _recordedOrders = {};
  List<CouponModel> get coupons => List.unmodifiable(_coupons);

  // Initial Mock Data (No Backend Required)
  List<GameModel> games = [
    GameModel(
      gameId: 'rov',
      gameName: 'RoV',
      shortName: 'RoV',
      category: 'Mobile',
      unit: 'coupons',
      uidPattern: r'^[0-9]{10,12}$',
      requiresServer: false,
      isActive: true,
      isPopular: true,
    ),
    GameModel(
      gameId: 'ff',
      gameName: 'Free Fire',
      shortName: 'FF',
      category: 'Mobile',
      unit: 'gems',
      uidPattern: r'^[0-9]{9,11}$',
      requiresServer: false,
      isActive: true,
      isPopular: true,
    ),
    GameModel(
      gameId: 'pubg',
      gameName: 'PUBG Mobile',
      shortName: 'PG',
      category: 'Mobile',
      unit: 'UC',
      uidPattern: r'^[0-9]{10,12}$',
      requiresServer: false,
      isActive: true,
      isPopular: true,
    ),
    GameModel(
      gameId: 'genshin',
      gameName: 'Genshin Impact',
      shortName: 'GI',
      category: 'Mobile',
      unit: 'Crystals',
      uidPattern: r'^[0-9]{9}$',
      requiresServer: true,
      isActive: true,
      isPopular: false,
    ),
    GameModel(
      gameId: 'valorant',
      gameName: 'Valorant',
      shortName: 'VP',
      category: 'PC',
      unit: 'VP',
      uidPattern: r'^.+#.+$',
      requiresServer: false,
      isActive: true,
      isPopular: true,
    ),
    GameModel(
      gameId: 'mlbb',
      gameName: 'Mobile Legends',
      shortName: 'ML',
      category: 'Mobile',
      unit: 'gems',
      uidPattern: r'^[0-9]{8,10}$',
      requiresServer: true,
      isActive: true,
      isPopular: false,
    ),
  ];

  Map<String, List<PackageModel>> gamePackages = {
    'rov': [
      PackageModel(
        packageId: 101,
        gameId: 'rov',
        packageName: '40 coupons',
        price: 35,
        isActive: true,
      ),
      PackageModel(
        packageId: 102,
        gameId: 'rov',
        packageName: '90 coupons',
        price: 79,
        isActive: true,
      ),
      PackageModel(
        packageId: 103,
        gameId: 'rov',
        packageName: '230 coupons',
        price: 199,
        isActive: true,
      ),
      PackageModel(
        packageId: 104,
        gameId: 'rov',
        packageName: '400 coupons',
        price: 350,
        isActive: true,
      ),
    ],
    'ff': [
      PackageModel(
        packageId: 201,
        gameId: 'ff',
        packageName: '100 gems',
        price: 39,
        isActive: true,
      ),
      PackageModel(
        packageId: 202,
        gameId: 'ff',
        packageName: '310 gems',
        price: 119,
        isActive: true,
      ),
    ],
    'genshin': [
      PackageModel(
        packageId: 301,
        gameId: 'genshin',
        packageName: '60 Crystals',
        price: 35,
        isActive: true,
      ),
      PackageModel(
        packageId: 302,
        gameId: 'genshin',
        packageName: '300 Crystals',
        price: 179,
        isActive: true,
      ),
    ],
  };

  List<RewardHistory> pointHistory = [];

  Future<void> loadCatalog() async {
    try {
      games = await GameService.getActiveGames();
      notifyListeners();
    } catch (_) {
      // Keep the existing catalogue visible when the server is offline.
    }
  }

  // Login with backend
  Future<void> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw Exception("Please enter username and password");
    }

    final response = await AuthService.login(username.trim(), password);
    final user = response['user'];
    final token = response['token']?.toString();

    if (user is! Map) {
      throw Exception("Invalid user information");
    }

    if (token == null || token.isEmpty) {
      throw Exception("Invalid authentication token");
    }

    final userId = int.tryParse(user['id'].toString());

    if (userId == null) {
      throw Exception("Invalid user ID");
    }

    final role = user['role']?.toString();

    if (role != 'admin' && role != 'user') {
      throw Exception("Invalid user role");
    }

    // Update user information
    currentUserId = userId;
    currentUsername = user['username']?.toString() ?? username.trim();
    currentDisplayName = user['display_name']?.toString() ?? '';
    currentRole = role!;

    // Save JWT token
    authToken = token;
    _coupons.clear();
    userPointsBalance = 0;
    pointHistory.clear();
    await refreshWallet();
    notifyListeners();
  }

  // logout

  Future<void> logout() async {
    try {
      await AuthService.logout();
    } finally {
      // Clear authentication data
      authToken = null;
      currentUserId = null;
      currentUsername = '';
      currentDisplayName = '';
      currentRole = 'user';

      // Clear account-specific data
      latestOrder = null;
      userPointsBalance = 0;
      pointHistory.clear();
      _coupons.clear();
      _recordedOrders.clear();
      walletError = null;

      notifyListeners();
    }
  }

  void addOrder(OrderModel order) {
    if (order.status != 'completed' || !_recordedOrders.add(order.orderId)) {
      return;
    }
    latestOrder = order;
    _coupons.removeWhere((coupon) => coupon.id == order.couponId);
    userPointsBalance = order.pointsBalance;

    final dateStr =
        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year + 543}';

    pointHistory.insert(
      0,
      RewardHistory(
        title: 'เติม ${order.gameName} · ${order.orderId}',
        date: dateStr,
        amount: '+${order.earnedPoints}',
        isEarned: true,
      ),
    );

    if (order.spentPoints > 0) {
      pointHistory.insert(
        1,
        RewardHistory(
          title: 'ใช้แต้มเป็นส่วนลด · ${order.orderId}',
          date: dateStr,
          amount: '−${order.spentPoints}',
          isEarned: false,
        ),
      );
    }

    notifyListeners();
  }

  Future<void> refreshWallet() async {
    if (authToken == null) return;
    final token = authToken;
    try {
      final results = await Future.wait([
        ApiService.get('/coupons'),
        ApiService.get('/points/balance'),
        ApiService.get('/points/history'),
      ]);
      if (token != authToken) return;
      _coupons.clear();
      _coupons.addAll(
        (results[0] as List).map(
          (row) => CouponModel(
            id: row['coupon_id'].toString(),
            name: row['name'].toString(),
            amountSatang: row['amount_satang'] as int,
            percent: row['percent'] as int,
            minimumSatang: row['minimum_satang'] as int,
            status: row['status'].toString(),
          ),
        ),
      );
      userPointsBalance = int.parse(results[1]['total_points'].toString());
      pointHistory = (results[2] as List).map((row) {
        final amount = int.parse(row['points_delta'].toString());
        return RewardHistory(
          title: row['type'].toString(),
          date: row['created_at'].toString(),
          amount: '${amount >= 0 ? '+' : ''}$amount',
          isEarned: amount >= 0,
        );
      }).toList();
      walletError = null;
    } catch (error) {
      if (token != authToken) return;
      walletError = 'โหลดคูปองและคอยน์ไม่สำเร็จ กรุณาลองใหม่';
    }
    notifyListeners();
  }

  Future<bool> redeemReward(RewardItem reward) async {
    if (authToken == null) return false;
    await ApiService.post('/coupons/redeem', {'reward_id': reward.id});
    await refreshWallet();
    return true;
  }
}
