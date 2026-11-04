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
      userId: json['user_id'],
      username: json['username'],
      displayName: json['display_name'] ?? '',
      role: json['role'],
      isActive: json['is_active'] == 1,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class GameModel {
  final int gameId;
  final String gameName;
  final String category;
  final String uidPattern;
  final bool requiresServer;
  final bool isActive;

  GameModel({
    required this.gameId,
    required this.gameName,
    required this.category,
    required this.uidPattern,
    required this.requiresServer,
    required this.isActive,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      gameId: json['game_id'],
      gameName: json['game_name'],
      category: json['category'],
      uidPattern: json['uid_pattern'],
      requiresServer: json['requires_server'] == 1,
      isActive: json['is_active'] == 1,
    );
  }
}

class PackageModel {
  final int packageId;
  final int gameId;
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

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      packageId: json['package_id'],
      gameId: json['game_id'],
      packageName: json['package_name'],
      price: double.parse(json['price'].toString()),
      isActive: json['is_active'] == 1,
    );
  }
}

class OrderModel {
  final int orderId;
  final int userId;
  final int packageId;
  final String playerUid;
  final String serverCode;
  final String gameNameSnapshot;
  final String packageNameSnapshot;
  final double originalPrice;
  final double discountAmount;
  final double totalAmount;
  final String status;
  final String createdAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.packageId,
    required this.playerUid,
    required this.serverCode,
    required this.gameNameSnapshot,
    required this.packageNameSnapshot,
    required this.originalPrice,
    required this.discountAmount,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'],
      userId: json['user_id'],
      packageId: json['package_id'],
      playerUid: json['player_uid'],
      serverCode: json['server_code'] ?? '',
      gameNameSnapshot: json['game_name_snapshot'],
      packageNameSnapshot: json['package_name_snapshot'],
      originalPrice: double.parse(json['original_price'].toString()),
      discountAmount: double.parse(json['discount_amount'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class PaymentModel {
  final int paymentId;
  final int orderId;
  final String transactionRef;
  final String method;
  final double amount;
  final String status;
  final String createdAt;
  final String? paidAt;

  PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.transactionRef,
    required this.method,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['payment_id'],
      orderId: json['order_id'],
      transactionRef: json['transaction_ref'],
      method: json['method'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
      createdAt: json['created_at'] ?? '',
      paidAt: json['paid_at'],
    );
  }
}

class PointTransactionModel {
  final int pointTransactionId;
  final int userId;
  final int orderId;
  final String eventKey;
  final String type;
  final int pointsDelta;
  final String createdAt;

  PointTransactionModel({
    required this.pointTransactionId,
    required this.userId,
    required this.orderId,
    required this.eventKey,
    required this.type,
    required this.pointsDelta,
    required this.createdAt,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointTransactionModel(
      pointTransactionId: json['point_transaction_id'],
      userId: json['user_id'],
      orderId: json['order_id'],
      eventKey: json['event_key'],
      type: json['type'],
      pointsDelta: json['points_delta'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ReceiptModel {
  final int receiptId;
  final int orderId;
  final String receiptNumber;
  final String issuedAt;

  ReceiptModel({
    required this.receiptId,
    required this.orderId,
    required this.receiptNumber,
    required this.issuedAt,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      receiptId: json['receipt_id'],
      orderId: json['order_id'],
      receiptNumber: json['receipt_number'],
      issuedAt: json['issued_at'] ?? '',
    );
  }
}
