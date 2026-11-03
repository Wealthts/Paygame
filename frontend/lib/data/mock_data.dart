import '../models/point_transaction.dart';
import '../models/receipt.dart';
import '../models/reward.dart';

/// ข้อมูลจำลอง (No front-back connection)
/// ตอนเชื่อม API ให้แทนที่ไฟล์นี้ด้วย service ที่เรียก Node.js
class MockData {
  MockData._();

  static final Receipt latestReceipt = Receipt(
    receiptNumber: 'GP-20261029-0042',
    orderCode: 'GP-0042',
    issuedAt: DateTime(2026, 10, 29, 16, 42),
    gameName: 'ROV',
    packageName: '400 คูปอง',
    playerUid: '1234567890',
    paymentMethod: 'QR พร้อมเพย์',
    originalPrice: 350,
    discountAmount: 10,
    pointsUsed: 100,
    pointsEarned: 34,
    pointsBalanceAfter: 1184,
    status: 'success',
  );

  static const List<Reward> rewards = [
    Reward(id: 1, name: 'ส่วนลด 20 บาท (ทุกเกม)', tag: '฿20', pointsCost: 200, discountValue: 20),
    Reward(id: 2, name: 'ส่วนลด 50 บาท (ขั้นต่ำ ฿300)', tag: '฿50', pointsCost: 450, discountValue: 50),
    Reward(id: 3, name: 'คูปองลด 5% ไม่จำกัดยอด', tag: '5%', pointsCost: 800, discountValue: 5),
    Reward(id: 4, name: 'ส่วนลด 150 บาท (ขั้นต่ำ ฿1,000)', tag: '฿150', pointsCost: 1500, discountValue: 150),
  ];

  /// รวมกันได้ 1,184 แต้ม (ยอดแต้ม = SUM(points_delta))
  static List<PointTransaction> transactions() => [
        PointTransaction(
          description: 'เติม ROV · GP-0042',
          type: PointType.earn,
          pointsDelta: 34,
          createdAt: DateTime(2026, 10, 29, 16, 42),
        ),
        PointTransaction(
          description: 'ใช้เป็นส่วนลด · GP-0042',
          type: PointType.redeem,
          pointsDelta: -100,
          createdAt: DateTime(2026, 10, 29, 16, 41),
        ),
        PointTransaction(
          description: 'เติม Genshin · GP-0038',
          type: PointType.earn,
          pointsDelta: 53,
          createdAt: DateTime(2026, 10, 25, 20, 11),
        ),
        PointTransaction(
          description: 'ยอดสะสมก่อนหน้า',
          type: PointType.earn,
          pointsDelta: 1147,
          createdAt: DateTime(2026, 10, 1, 9, 0),
        ),
        PointTransaction(
          description: 'โบนัสสมัครสมาชิก',
          type: PointType.adjust,
          pointsDelta: 50,
          createdAt: DateTime(2026, 9, 15, 10, 0),
        ),
      ];
}
