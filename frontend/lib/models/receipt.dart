/// Model ใบเสร็จ (รวมข้อมูลจากตาราง ORDERS + RECEIPTS + PAYMENTS)
class Receipt {
  final String receiptNumber;
  final String orderCode;
  final DateTime issuedAt;
  final String gameName;
  final String packageName;
  final String playerUid;
  final String paymentMethod;
  final double originalPrice;
  final double discountAmount;
  final int pointsUsed;
  final int pointsEarned;
  final int pointsBalanceAfter;
  final String status; // success | failed

  const Receipt({
    required this.receiptNumber,
    required this.orderCode,
    required this.issuedAt,
    required this.gameName,
    required this.packageName,
    required this.playerUid,
    required this.paymentMethod,
    required this.originalPrice,
    required this.discountAmount,
    required this.pointsUsed,
    required this.pointsEarned,
    required this.pointsBalanceAfter,
    required this.status,
  });

  double get totalAmount => originalPrice - discountAmount;
  bool get isSuccess => status == 'success';

  /// ใช้ตอนเชื่อม Backend (Sprint 4): แปลง JSON จาก GET /receipts/:orderId
  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        receiptNumber: json['receipt_number'] as String,
        orderCode: json['order_code'] as String,
        issuedAt: DateTime.parse(json['issued_at'] as String),
        gameName: json['game_name_snapshot'] as String,
        packageName: json['package_name_snapshot'] as String,
        playerUid: json['player_uid'] as String,
        paymentMethod: json['method'] as String,
        originalPrice: (json['original_price'] as num).toDouble(),
        discountAmount: (json['discount_amount'] as num).toDouble(),
        pointsUsed: json['points_used'] as int,
        pointsEarned: json['points_earned'] as int,
        pointsBalanceAfter: json['points_balance'] as int,
        status: json['status'] as String,
      );
}
