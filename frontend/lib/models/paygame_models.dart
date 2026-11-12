class UserModel {
  final int userId;
  final String username;
  final String email;
  final String displayName;
  final String role;
  final bool isActive;
  final String createdAt;

  UserModel({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['is_active'] == 1,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'display_name': displayName,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
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

  GameModel({
    required this.gameId,
    required this.gameName,
    required this.shortName,
    required this.category,
    required this.unit,
    required this.uidPattern,
    required this.requiresServer,
    required this.isActive
  });

  // Convert JSON to GameModel
  factory GameModel.fromJson(Map<String, dynamic> json) {
    final name = json['game_name'] ?? '';
    final short = json['short_name'] ?? name;
    return GameModel(
      gameId: json['game_id'].toString(),
      gameName: name,
      shortName: short,
      category: json['category'] ?? '',
      unit: json['unit'] ?? '',
      uidPattern: json['uid_pattern'] ?? '',
      requiresServer: _readBool(json['requires_server']),
      isActive: _readBool(json['is_active']),
    );
  }

  // Convert GameModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'game_name': gameName,
      'category': category,
      'uid_pattern': uidPattern,
      'requires_server': requiresServer ? 1 : 0,
      'is_active': isActive ? 1 : 0,
    };
  }
}

class PackageModel {
  final int packageId;
  final String gameId;
  final String packageName;
  final double price;
  final bool isActive;

  PackageModel({
    required this.packageId,
    required this.gameId,
    required this.packageName,
    required this.price,
    required this.isActive,
  });

  // Convert JSON to PackageModel
  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      packageId: int.tryParse(json['package_id'].toString()) ?? 0,
      gameId: json['game_id'].toString(),
      packageName: json['package_name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      isActive: _readBool(json['is_active']),
    );
  }

  // Convert PackageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'game_id': int.tryParse(gameId) ?? 0,
      'package_name': packageName,
      'price': price,
      'is_active': isActive ? 1 : 0,
    };
  }
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
  final int spentPoints;
  final String? couponId;

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
    this.spentPoints = 0,
    this.couponId,
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

// Convert database boolean values
bool _readBool(dynamic value) {
  if (value == true || value == 1 || value == '1') {
    return true;
  }

  return false;
}

class CouponModel {
  const CouponModel({
    required this.id,
    required this.name,
    this.amountSatang = 0,
    this.percent = 0,
    this.minimumSatang = 0,
    this.maxDiscountSatang,
    this.status = 'Available',
  });
  final String id, name;
  final String status;
  final int amountSatang, percent, minimumSatang;

  /// Highest discount a percent coupon can give; null = no cap.
  final int? maxDiscountSatang;

  /// Short Thai description, e.g. "ลด 20% (สูงสุด ฿50)".
  String get description {
    if (percent > 0) {
      return maxDiscountSatang == null
          ? 'ลด $percent%'
          : 'ลด $percent% (สูงสุด ฿${maxDiscountSatang! ~/ 100})';
    }
    return 'ลด ฿${amountSatang ~/ 100}';
  }

  int discountFor(int price) {
    if (status != 'Available' || price < minimumSatang || price <= 0) return 0;
    var discount = percent > 0 ? price * percent ~/ 100 : amountSatang;
    if (maxDiscountSatang != null && discount > maxDiscountSatang!) {
      discount = maxDiscountSatang!;
    }
    return discount.clamp(0, price);
  }
}

class CheckoutDiscount {
  CheckoutDiscount({
    required int priceSatang,
    required int points,
    bool usePoints = false,
    CouponModel? coupon,
  }) {
    couponSatang = coupon?.discountFor(priceSatang) ?? 0;
    spentPoints = usePoints
        ? points.clamp(0, (priceSatang - couponSatang) ~/ 10)
        : 0;
  }
  late final int couponSatang, spentPoints;
  int get coinSatang => spentPoints * 10;
  int get totalSatang => couponSatang + coinSatang;
}
