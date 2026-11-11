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

  List<GameModel> games = [];

  List<RewardHistory> pointHistory = [];

  Future<void> loadCatalog() async {
    try {
      games = await GameService.getActiveGames();
      notifyListeners();
    } catch (_) {
      // Server offline: the game list stays empty until the next refresh.
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
            amountSatang: (row['amount_satang'] as num).toInt(),
            percent: (row['percent'] as num).toInt(),
            minimumSatang: (row['minimum_satang'] as num).toInt(),
            maxDiscountSatang: (row['max_discount_satang'] as num?)?.toInt(),
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

  /// Adds a coupon to the user's wallet by typing its code (e.g. WELCOME10).
  Future<void> claimCoupon(String code) async {
    if (authToken == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');
    await ApiService.post('/coupons/claim', {'code': code.trim()});
    await refreshWallet();
  }

  Future<bool> redeemReward(RewardItem reward) async {
    if (authToken == null) return false;
    await ApiService.post('/coupons/redeem', {'reward_id': reward.id});
    await refreshWallet();
    return true;
  }
}
