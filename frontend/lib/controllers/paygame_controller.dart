import 'package:flutter/material.dart';
import 'package:frontend/models/paygame_models.dart';

class PaygameController extends ChangeNotifier {
  String? authToken;
  String currentRole = 'user';
  String currentUsername = 'Natthawat';
  int userPointsBalance = 2000;

  OrderModel? latestOrder;

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
        quantity: 40,
        price: 35,
        isActive: true,
      ),
      PackageModel(
        packageId: 102,
        gameId: 'rov',
        packageName: '90 coupons',
        quantity: 90,
        price: 79,
        isActive: true,
      ),
      PackageModel(
        packageId: 103,
        gameId: 'rov',
        packageName: '230 coupons',
        quantity: 230,
        price: 199,
        isActive: true,
      ),
      PackageModel(
        packageId: 104,
        gameId: 'rov',
        packageName: '400 coupons',
        quantity: 400,
        price: 350,
        isActive: true,
      ),
    ],
    'ff': [
      PackageModel(
        packageId: 201,
        gameId: 'ff',
        packageName: '100 gems',
        quantity: 100,
        price: 39,
        isActive: true,
      ),
      PackageModel(
        packageId: 202,
        gameId: 'ff',
        packageName: '310 gems',
        quantity: 310,
        price: 119,
        isActive: true,
      ),
    ],
    'genshin': [
      PackageModel(
        packageId: 301,
        gameId: 'genshin',
        packageName: '60 Crystals',
        quantity: 60,
        price: 35,
        isActive: true,
      ),
      PackageModel(
        packageId: 302,
        gameId: 'genshin',
        packageName: '300 Crystals',
        quantity: 300,
        price: 179,
        isActive: true,
      ),
    ],
  };

  List<RewardHistory> pointHistory = [
    const RewardHistory(
      title: 'แต้มเริ่มต้น',
      date: '',
      amount: '+2000',
      isEarned: true,
    ),
    const RewardHistory(
      title: 'เติม ROV · GP-0042',
      date: '29 Oct',
      amount: '+34',
      isEarned: true,
    ),
    const RewardHistory(
      title: 'ใช้แต้มเป็นส่วนลด · GP-0042',
      date: '29 Oct',
      amount: '−100',
      isEarned: false,
    ),
    const RewardHistory(
      title: 'เติม Genshin · GP-0038',
      date: '25 Oct',
      amount: '+53',
      isEarned: true,
    ),
    const RewardHistory(
      title: 'Sign-up Bonus',
      date: '15 Sep',
      amount: '+50',
      isEarned: true,
    ),
  ];

  bool login(String username, String password) {
    if (username.isEmpty || password.isEmpty) return false;
    authToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    currentUsername = username;
    currentRole = username.toLowerCase() == 'admin' ? 'admin' : 'user';
    notifyListeners();
    return true;
  }

  void addOrder(OrderModel order) {
    latestOrder = order;
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

    if (order.discountAmount > 0) {
      pointHistory.insert(
        1,
        RewardHistory(
          title: 'ใช้แต้มเป็นส่วนลด · ${order.orderId}',
          date: dateStr,
          amount: '−100',
          isEarned: false,
        ),
      );
    }

    notifyListeners();
  }

  bool redeemReward(RewardItem reward) {
    if (userPointsBalance < reward.cost) return false;

    userPointsBalance -= reward.cost;
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year + 543}';

    pointHistory.insert(
      0,
      RewardHistory(
        title: 'แลก ${reward.name}',
        date: dateStr,
        amount: '−${reward.cost}',
        isEarned: false,
      ),
    );

    notifyListeners();
    return true;
  }
}
