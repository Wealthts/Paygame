import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/paygame_models.dart';
import 'package:frontend/views/user/game_detail_view.dart';

void main() {
  const coupon = CouponModel(id: 'one', name: 'ลด 20 บาท', amountSatang: 2000);
  test('Coins use the whole balance, capped after the coupon discount', () {
    final full = CheckoutDiscount(
      priceSatang: 35000,
      points: 2000,
      usePoints: true,
      coupon: coupon,
    );
    expect(full.spentPoints, 2000);
    expect(full.totalSatang, 22000);
    final capped = CheckoutDiscount(
      priceSatang: 3500,
      points: 2000,
      usePoints: true,
      coupon: coupon,
    );
    expect(capped.spentPoints, 150);
    expect(capped.totalSatang, 3500);
    expect(
      CheckoutDiscount(
        priceSatang: 3500,
        points: 9,
        usePoints: true,
      ).coinSatang,
      90,
    );
  });
  test('Coupon minimum and percentage rounding are enforced', () {
    const minimum = CouponModel(
      id: 'min',
      name: '50',
      amountSatang: 5000,
      minimumSatang: 30000,
    );
    expect(minimum.discountFor(29999), 0);
    expect(minimum.discountFor(30000), 5000);
    const percent = CouponModel(id: 'percent', name: '5%', percent: 5);
    expect(percent.discountFor(19900), 995);
    expect(coupon.discountFor(1000), 1000);
  });
  testWidgets(
    'One coupon can replace another; unavailable coupons are disabled',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PaygamePayment(
            game: const PaygameGame('RoV', 'คูปอง', [PaygamePack(40, 35)]),
            pack: const PaygamePack(40, 35),
            uid: '1234567890',
            initialPoints: 2000,
            coupons: const [
              coupon,
              CouponModel(id: 'two', name: 'ลด 10 บาท', amountSatang: 1000),
              CouponModel(
                id: 'used',
                name: 'ใช้แล้ว',
                amountSatang: 2000,
                status: 'Used',
              ),
              CouponModel(
                id: 'min',
                name: 'ขั้นต่ำ 300',
                amountSatang: 5000,
                minimumSatang: 30000,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('เลือกคูปอง'));
      await tester.pumpAndSettle();
      expect(find.text('คูปองไม่พร้อมใช้'), findsOneWidget);
      expect(find.text('ยอดไม่ถึงขั้นต่ำ'), findsOneWidget);
      await tester.tap(find.text('ใช้คูปองนี้').first);
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันชำระเงิน ฿15'), findsOneWidget);
      await tester.tap(find.text('ลด 20 บาท'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ใช้คูปองนี้'));
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันชำระเงิน ฿25'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันชำระเงิน ฿0'), findsOneWidget);
      await tester.tap(find.text('ยืนยันชำระเงิน ฿0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กลับไปตรวจสอบ'));
      await tester.pumpAndSettle();
      expect(find.text('ลด 10 บาท'), findsOneWidget);
      expect(find.text('ยืนยันชำระเงิน ฿0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
