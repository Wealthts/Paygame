class UserModel {
  final int userId;
  final String username;
  final String displayName;
  final String role;
  final bool isActive;
  final String createdAt;

  UserModel({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['is_active'] == 1,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class GameModel {
  final String gameId;
  final String gameName;
  final String shortName;
  final String category;
  final String unit;
  final String uidPattern;
  final bool requiresServer;
  final bool isActive;
  final bool isPopular;

  GameModel({
    required this.gameId,
    required this.gameName,
    required this.shortName,
    required this.category,
    required this.unit,
    required this.uidPattern,
    required this.requiresServer,
    required this.isActive,
    this.isPopular = false,
  });
}

class PackageModel {
  final int packageId;
  final String gameId;
  final String packageName;
  final int quantity;
  final double price;
  final bool isActive;

  PackageModel({
    required this.packageId,
    required this.gameId,
    required this.packageName,
    required this.quantity,
    required this.price,
    required this.isActive,
  });
}

class OrderModel {
  final String orderId;
  final String gameName;
  final String packageName;
  final String playerUid;
  final String? serverCode;
  final double originalPrice;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final int earnedPoints;
  final int pointsBalance;
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.gameName,
    required this.packageName,
    required this.playerUid,
    this.serverCode,
    required this.originalPrice,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.earnedPoints,
    required this.pointsBalance,
    required this.createdAt,
  });
}

class RewardItem {
  final String id;
  final String tag;
  final String name;
  final int cost;
  final String description;

  const RewardItem({
    required this.id,
    required this.tag,
    required this.name,
    required this.cost,
    this.description = '',
  });
}

class RewardHistory {
  final String title;
  final String date;
  final String amount;
  final bool isEarned;

  const RewardHistory({
    required this.title,
    required this.date,
    required this.amount,
    required this.isEarned,
  });
}