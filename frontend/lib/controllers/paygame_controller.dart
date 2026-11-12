import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 💡 เพิ่ม Import
import '../services/api_service.dart'; //[cite: 13]
import 'package:frontend/models/paygame_models.dart'; //[cite: 13]
import 'package:frontend/services/auth_service.dart'; //[cite: 13]
import 'package:frontend/services/game_service.dart'; //[cite: 13]

class PaygameController extends ChangeNotifier {
  PaygameController() {
    loadCatalog(); //[cite: 13]
  }

  String? authToken; //[cite: 13]
  String currentRole = 'user'; //[cite: 13]
  String currentUsername = ''; //[cite: 13]
  int? currentUserId; //[cite: 13]
  String currentDisplayName = ''; //[cite: 13]
  int userPointsBalance = 0; //[cite: 13]
  String? walletError; //[cite: 13]

  OrderModel? latestOrder; //[cite: 13]
  final List<CouponModel> _coupons = []; //[cite: 13]
  final Set<String> recordedOrders = {}; //[cite: 13]
  List<RewardHistory> pointHistory = []; //[cite: 13]
  List<GameModel> games = []; //[cite: 13]
  List<CouponModel> get coupons => List.unmodifiable(_coupons);

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage(); // 💡 เพิ่ม Storage Instance[cite: 10]

  Future<void> loadCatalog() async {
    //[cite: 13]
    try {
      games = await GameService.getActiveGames(); //[cite: 13]
      notifyListeners(); //[cite: 13]
    } catch (_) {
      // Server offline: the game list stays empty until the next refresh.
    }
  }

  // 💡 ฟังก์ชันดึงข้อมูล Session เดิมเมื่อกด Reload / เปิดแอปใหม่
  Future<void> tryAutoLogin() async {
    final token = await ApiService.getToken(); //[cite: 10]
    if (token != null && token.isNotEmpty) {
      try {
        // อ่านข้อมูล User ที่เคยบันทึกไว้ใน Storage[cite: 10]
        final savedUserId = await _storage.read(key: 'user_id');
        final savedUsername = await _storage.read(key: 'username');
        final savedDisplayName = await _storage.read(key: 'display_name');
        final savedRole = await _storage.read(key: 'role');

        if (savedUserId != null && savedRole != null) {
          authToken = token;
          currentUserId = int.tryParse(savedUserId);
          currentUsername = savedUsername ?? '';
          currentDisplayName = savedDisplayName ?? '';
          currentRole = savedRole;

          await refreshWallet(); // โหลดคูปองและพอยต์ล่าสุด[cite: 13]
          notifyListeners(); //[cite: 13]
        }
      } catch (e) {
        debugPrint('Auto Login Failed: $e');
      }
    }
  }

  // Login with backend[cite: 13]
  Future<void> login(String username, String password) async {
    //[cite: 13]
    if (username.trim().isEmpty || password.isEmpty) {
      //[cite: 13]
      throw Exception("Please enter username and password"); //[cite: 13]
    }

    final response = await AuthService.login(
      username.trim(),
      password,
    ); //[cite: 13]
    final user = response['user']; //[cite: 13]
    final token = response['token']?.toString(); //[cite: 13]

    if (user is! Map) {
      //[cite: 13]
      throw Exception("Invalid user information"); //[cite: 13]
    }

    if (token == null || token.isEmpty) {
      //[cite: 13]
      throw Exception("Invalid authentication token"); //[cite: 13]
    }

    final userId = int.tryParse(user['id'].toString()); //[cite: 13]

    if (userId == null) {
      //[cite: 13]
      throw Exception("Invalid user ID"); //[cite: 13]
    }

    final role = user['role']?.toString(); //[cite: 13]

    if (role != 'admin' && role != 'user') {
      //[cite: 13]
      throw Exception("Invalid user role"); //[cite: 13]
    }

    // Update user information[cite: 13]
    currentUserId = userId; //[cite: 13]
    currentUsername =
        user['username']?.toString() ?? username.trim(); //[cite: 13]
    currentDisplayName = user['display_name']?.toString() ?? ''; //[cite: 13]
    currentRole = role!; //[cite: 13]

    // 💡 บันทึกข้อมูล User ลง Storage สำหรับ Auto-Login[cite: 10]
    await _storage.write(key: 'user_id', value: userId.toString());
    await _storage.write(key: 'username', value: currentUsername);
    await _storage.write(key: 'display_name', value: currentDisplayName);
    await _storage.write(key: 'role', value: currentRole);

    // Save JWT token[cite: 13]
    authToken = token; //[cite: 13]
    coupons.clear(); //[cite: 13]
    userPointsBalance = 0; //[cite: 13]
    pointHistory.clear(); //[cite: 13]
    await refreshWallet(); //[cite: 13]
    notifyListeners(); //[cite: 13]
  }

  // logout[cite: 13]
  Future<void> logout() async {
    //[cite: 13]
    try {
      await AuthService.logout(); //[cite: 13]
    } finally {
      // 💡 ลบข้อมูล User จาก Storage เมื่อ Logout[cite: 10]
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'username');
      await _storage.delete(key: 'display_name');
      await _storage.delete(key: 'role');

      // Clear authentication data[cite: 13]
      authToken = null; //[cite: 13]
      currentUserId = null; //[cite: 13]
      currentUsername = ''; //[cite: 13]
      currentDisplayName = ''; //[cite: 13]
      currentRole = 'user'; //[cite: 13]

      // Clear account-specific data[cite: 13]
      latestOrder = null; //[cite: 13]
      userPointsBalance = 0; //[cite: 13]
      pointHistory.clear(); //[cite: 13]
      coupons.clear(); //[cite: 13]
      recordedOrders.clear(); //[cite: 13]
      walletError = null; //[cite: 13]

      notifyListeners(); //[cite: 13]
    }
  }

  void addOrder(OrderModel order) {
    //[cite: 13]
    if (order.status != 'completed' || !recordedOrders.add(order.orderId)) {
      //[cite: 13]
      return; //[cite: 13]
    }
    latestOrder = order; //[cite: 13]
    coupons.removeWhere((coupon) => coupon.id == order.couponId); //[cite: 13]
    userPointsBalance = order.pointsBalance; //[cite: 13]

    final dateStr =
        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year + 543}'; //[cite: 13]

    pointHistory.insert(
      //[cite: 13]
      0,
      RewardHistory(
        //[cite: 13]
        title: 'เติม ${order.gameName} · ${order.orderId}', //[cite: 13]
        date: dateStr, //[cite: 13]
        amount: '+${order.earnedPoints}', //[cite: 13]
        isEarned: true, //[cite: 13]
      ),
    );

    if (order.spentPoints > 0) {
      //[cite: 13]
      pointHistory.insert(
        //[cite: 13]
        1,
        RewardHistory(
          //[cite: 13]
          title: 'ใช้แต้มเป็นส่วนลด · ${order.orderId}', //[cite: 13]
          date: dateStr, //[cite: 13]
          amount: '−${order.spentPoints}', //[cite: 13]
          isEarned: false, //[cite: 13]
        ),
      );
    }

    notifyListeners(); //[cite: 13]
  }

  Future<void> refreshWallet() async {
    //[cite: 13]
    if (authToken == null) return; //[cite: 13]
    final token = authToken; //[cite: 13]
    try {
      final results = await Future.wait([
        //[cite: 13]
        ApiService.get('/coupons'), //[cite: 13]
        ApiService.get('/points/balance'), //[cite: 13]
        ApiService.get('/points/history'), //[cite: 13]
      ]);
      if (token != authToken) return; //[cite: 13]
      coupons.clear(); //[cite: 13]
      coupons.addAll(
        //[cite: 13]
        (results[0] as List).map(
          //[cite: 13]
          (row) => CouponModel(
            //[cite: 13]
            id: row['coupon_id'].toString(), //[cite: 13]
            name: row['name'].toString(), //[cite: 13]
            amountSatang: (row['amount_satang'] as num).toInt(), //[cite: 13]
            percent: (row['percent'] as num).toInt(), //[cite: 13]
            minimumSatang: (row['minimum_satang'] as num).toInt(), //[cite: 13]
            maxDiscountSatang: (row['max_discount_satang'] as num?)
                ?.toInt(), //[cite: 13]
            status: row['status'].toString(), //[cite: 13]
          ),
        ),
      );
      userPointsBalance = int.parse(
        results[1]['total_points'].toString(),
      ); //[cite: 13]
      pointHistory = (results[2] as List).map((row) {
        //[cite: 13]
        final amount = int.parse(row['points_delta'].toString()); //[cite: 13]
        return RewardHistory(
          //[cite: 13]
          title: row['type'].toString(), //[cite: 13]
          date: row['created_at'].toString(), //[cite: 13]
          amount: '${amount >= 0 ? '+' : ''}$amount', //[cite: 13]
          isEarned: amount >= 0, //[cite: 13]
        );
      }).toList();
      walletError = null; //[cite: 13]
    } catch (error) {
      if (token != authToken) return; //[cite: 13]
      walletError = 'โหลดคูปองและคอยน์ไม่สำเร็จ กรุณาลองใหม่'; //[cite: 13]
    }
    notifyListeners(); //[cite: 13]
  }

  Future<void> claimCoupon(String code) async {
    //[cite: 13]
    if (authToken == null) throw Exception('กรุณาเข้าสู่ระบบก่อน'); //[cite: 13]
    await ApiService.post('/coupons/claim', {'code': code.trim()}); //[cite: 13]
    await refreshWallet(); //[cite: 13]
  }

  Future<bool> redeemReward(RewardItem reward) async {
    //[cite: 13]
    if (authToken == null) return false; //[cite: 13]
    await ApiService.post('/coupons/redeem', {
      'reward_id': reward.id,
    }); //[cite: 13]
    await refreshWallet(); //[cite: 13]
    return true; //[cite: 13]
  }
}
