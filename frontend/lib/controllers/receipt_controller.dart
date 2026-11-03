import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/receipt.dart';

/// Controller ของหน้าใบเสร็จ (MVC: ฝั่ง Controller)
class ReceiptController extends ChangeNotifier {
  Receipt? _receipt;
  bool _loading = false;

  Receipt? get receipt => _receipt;
  bool get isLoading => _loading;

  /// โหลดใบเสร็จของออเดอร์
  /// (Sprint 4: เปลี่ยนเป็นเรียก GET /receipts/:orderId)
  Future<void> load(String orderCode) async {
    _loading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _receipt = MockData.latestReceipt;
    _loading = false;
    notifyListeners();
  }

  /// ข้อความสำหรับคัดลอก/แชร์ใบเสร็จ
  String toShareText(Receipt r) => [
        'GamePay E-Receipt',
        'เลขที่: ${r.receiptNumber}',
        'เกม: ${r.gameName} · ${r.packageName}',
        'UID: ${r.playerUid}',
        'ยอดชำระ: ${r.totalAmount.toStringAsFixed(2)} บาท',
      ].join('\n');
}
