import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/point_transaction.dart';
import '../models/reward.dart';

/// ระดับสมาชิกตามแต้มสะสม
class MemberTier {
  final String name;
  final int minPoints;
  final int? nextAt; // null = ระดับสูงสุด
  final String? nextName;

  const MemberTier(this.name, this.minPoints, this.nextAt, this.nextName);
}

/// Controller ของระบบแต้ม (MVC: ฝั่ง Controller)
class PointsController extends ChangeNotifier {
  /// เติมทุก 10 บาท ได้ 1 แต้ม
  static const int bahtPerPoint = 10;

  static const tiers = [
    MemberTier('SILVER', 0, 1000, 'Gold'),
    MemberTier('GOLD', 1000, 2000, 'Platinum'),
    MemberTier('PLATINUM', 2000, null, null),
  ];

  final List<PointTransaction> _transactions = MockData.transactions();
  final List<Reward> rewards = MockData.rewards;

  List<PointTransaction> get transactions => List.unmodifiable(_transactions);

  /// ยอดแต้มคงเหลือ = SUM(points_delta)
  int get balance => _transactions.fold(0, (sum, t) => sum + t.pointsDelta);

  MemberTier get tier => tiers.lastWhere((t) => balance >= t.minPoints);

  /// 0.0 - 1.0 ความคืบหน้าไประดับถัดไป
  double get tierProgress {
    final t = tier;
    if (t.nextAt == null) return 1;
    return ((balance - t.minPoints) / (t.nextAt! - t.minPoints)).clamp(0.0, 1.0).toDouble();
  }

  int get pointsToNextTier => tier.nextAt == null ? 0 : tier.nextAt! - balance;

  /// คำนวณแต้มที่ได้จากยอดชำระ
  static int calculateEarnedPoints(double paidAmount) => paidAmount ~/ bahtPerPoint;

  bool canRedeem(Reward reward) => balance >= reward.pointsCost;

  /// แลกรางวัล: คืนค่า true ถ้าสำเร็จ
  /// (Sprint 4: เปลี่ยนเป็นเรียก POST /rewards/:id/redeem)
  bool redeem(Reward reward) {
    if (!canRedeem(reward)) return false;
    _transactions.insert(
      0,
      PointTransaction(
        description: 'แลก ${reward.name}',
        type: PointType.redeem,
        pointsDelta: -reward.pointsCost,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }
}
