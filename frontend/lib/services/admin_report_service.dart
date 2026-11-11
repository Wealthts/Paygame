import 'api_service.dart';

// ======================================================================
// Models for the admin Receipts and Points pages
// (data comes from backend/routes/admin_reports.js)
// ======================================================================

/// One receipt row: receipts JOIN orders, users, payments
class AdminReceiptItem {
  final int receiptId;
  final String receiptNumber;
  final DateTime issuedAt;
  final int orderId;
  final String username;
  final String displayName;
  final String gameName;
  final String packageName;
  final String playerUid;
  final String? serverCode;
  final String method;
  final String paymentStatus;
  final double originalPrice;
  final double discountAmount;
  final double feeAmount;
  final double totalAmount;
  final int spentPoints;
  final String? couponCode;

  const AdminReceiptItem({
    required this.receiptId,
    required this.receiptNumber,
    required this.issuedAt,
    required this.orderId,
    required this.username,
    required this.displayName,
    required this.gameName,
    required this.packageName,
    required this.playerUid,
    required this.serverCode,
    required this.method,
    required this.paymentStatus,
    required this.originalPrice,
    required this.discountAmount,
    required this.feeAmount,
    required this.totalAmount,
    required this.spentPoints,
    required this.couponCode,
  });

  factory AdminReceiptItem.fromJson(Map<String, dynamic> j) => AdminReceiptItem(
        receiptId: _toInt(j['receipt_id']),
        receiptNumber: '${j['receipt_number'] ?? ''}',
        issuedAt: _toDate(j['issued_at']),
        orderId: _toInt(j['order_id']),
        username: '${j['username'] ?? ''}',
        displayName: '${j['display_name'] ?? ''}',
        gameName: '${j['game_name_snapshot'] ?? ''}',
        packageName: '${j['package_name_snapshot'] ?? ''}',
        playerUid: '${j['player_uid'] ?? ''}',
        serverCode: _emptyToNull(j['server_code']),
        method: '${j['method'] ?? '-'}',
        paymentStatus: '${j['payment_status'] ?? '-'}',
        originalPrice: _toDouble(j['original_price']),
        discountAmount: _toDouble(j['discount_amount']),
        feeAmount: _toDouble(j['fee_amount']),
        totalAmount: _toDouble(j['total_amount']),
        spentPoints: _toInt(j['spent_points']),
        couponCode: _emptyToNull(j['coupon_code_snapshot']),
      );
}

/// Current balance of one user (SUM of points_delta)
class AdminPointBalance {
  final int userId;
  final String username;
  final String displayName;
  final int balance;
  final int earnedTotal;

  const AdminPointBalance({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.balance,
    required this.earnedTotal,
  });

  factory AdminPointBalance.fromJson(Map<String, dynamic> j) => AdminPointBalance(
        userId: _toInt(j['user_id']),
        username: '${j['username'] ?? ''}',
        displayName: '${j['display_name'] ?? ''}',
        balance: _toInt(j['balance']),
        earnedTotal: _toInt(j['earned_total']),
      );
}

/// One row of point_transactions (type: Earn, Spend, Redeem, Refund)
class AdminPointTx {
  final int id;
  final String username;
  final int? orderId;
  final String type;
  final int pointsDelta;
  final String? gameName;
  final String? packageName;
  final DateTime createdAt;

  const AdminPointTx({
    required this.id,
    required this.username,
    required this.orderId,
    required this.type,
    required this.pointsDelta,
    required this.gameName,
    required this.packageName,
    required this.createdAt,
  });

  factory AdminPointTx.fromJson(Map<String, dynamic> j) => AdminPointTx(
        id: _toInt(j['point_transaction_id']),
        username: '${j['username'] ?? ''}',
        orderId: j['order_id'] == null ? null : _toInt(j['order_id']),
        type: '${j['type'] ?? ''}',
        pointsDelta: _toInt(j['points_delta']),
        gameName: _emptyToNull(j['game_name_snapshot']),
        packageName: _emptyToNull(j['package_name_snapshot']),
        createdAt: _toDate(j['created_at']),
      );

  /// Short description shown in the list
  String get note {
    final item = [gameName, packageName].whereType<String>().join(' ');
    switch (type.toLowerCase()) {
      case 'earn':
        return item.isEmpty ? 'Earned from top-up' : 'Top-up $item';
      case 'spend':
        return 'Used as discount';
      case 'redeem':
        return 'Redeemed for a coupon';
      case 'refund':
        return 'Refund (payment rejected)';
      default:
        return type;
    }
  }
}

// ======================================================================
// API calls (admin token is sent automatically by ApiService)
// ======================================================================
class AdminReportService {
  static Future<List<AdminReceiptItem>> fetchReceipts() async {
    final data = await ApiService.get('/admin/receipts');
    return (data as List)
        .map((e) => AdminReceiptItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<AdminPointBalance>> fetchPointBalances() async {
    final data = await ApiService.get('/admin/points/balances');
    return (data as List)
        .map((e) => AdminPointBalance.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<AdminPointTx>> fetchPointHistory() async {
    final data = await ApiService.get('/admin/points/history');
    return (data as List)
        .map((e) => AdminPointTx.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

// ======================================================================
// Parsing helpers (MySQL DECIMAL arrives as a String, DATETIME as ISO UTC)
// ======================================================================
int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? double.tryParse('$v')?.toInt() ?? 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

DateTime _toDate(dynamic v) {
  final parsed = DateTime.tryParse('$v');
  return (parsed ?? DateTime.fromMillisecondsSinceEpoch(0)).toLocal();
}

String? _emptyToNull(dynamic v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}
