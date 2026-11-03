import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/points_controller.dart';
import 'package:frontend/models/reward.dart';

void main() {
  group('PointsController', () {
    test('ยอดแต้มเริ่มต้น = ผลรวม points_delta', () {
      expect(PointsController().balance, 1184);
    });

    test('เติมทุก 10 บาท ได้ 1 แต้ม (ปัดเศษลง)', () {
      expect(PointsController.calculateEarnedPoints(340), 34);
      expect(PointsController.calculateEarnedPoints(79), 7);
      expect(PointsController.calculateEarnedPoints(9), 0);
    });

    test('ระดับสมาชิก GOLD และแต้มที่ต้องสะสมเพิ่ม', () {
      final c = PointsController();
      expect(c.tier.name, 'GOLD');
      expect(c.pointsToNextTier, 816);
    });

    test('แลกรางวัลสำเร็จแล้วแต้มลดลง', () {
      final c = PointsController();
      final ok = c.redeem(c.rewards.first); // 200 แต้ม
      expect(ok, isTrue);
      expect(c.balance, 984);
    });

    test('แต้มไม่พอ แลกไม่ได้', () {
      final c = PointsController();
      const expensive = Reward(id: 99, name: 'test', tag: 'x', pointsCost: 5000, discountValue: 1);
      expect(c.redeem(expensive), isFalse);
      expect(c.balance, 1184);
    });
  });
}
