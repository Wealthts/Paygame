import 'package:flutter/material.dart';
import '../../models/paygame_models.dart';

class CouponsView extends StatelessWidget {
  const CouponsView({
    super.key,
    required this.coupons,
    this.priceSatang,
    this.selectedId,
    this.onRefresh,
    this.error,
  });
  final List<CouponModel> coupons;
  final int? priceSatang;
  final String? selectedId;
  final String? error;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(priceSatang == null ? 'คูปองของฉัน' : 'เลือกคูปอง'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'ใช้คูปองได้ 1 ใบต่อรายการ ใช้ร่วมกับคอยน์ได้',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('แลกคูปองได้ที่เมนูแลกรางวัล'),
            const SizedBox(height: 20),
            if (error != null) Text(error!),
            if (onRefresh != null)
              TextButton(
                onPressed: onRefresh,
                child: const Text('รีเฟรชคูปองและคอยน์'),
              ),
            if (coupons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 64),
                    SizedBox(height: 16),
                    Text('ยังไม่มีคูปอง'),
                    Text('นำคอยน์ไปแลกคูปองที่เมนูแลกรางวัล'),
                  ],
                ),
              ),
            for (final coupon in coupons)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        coupon.minimumSatang == 0
                            ? 'ไม่มีขั้นต่ำ'
                            : 'ยอดขั้นต่ำ ฿${coupon.minimumSatang ~/ 100}',
                      ),
                      Text(
                        coupon.status == 'Reserved'
                            ? 'รออนุมัติรายการ'
                            : coupon.status == 'Used'
                            ? 'ใช้แล้ว'
                            : 'ใช้ได้ครั้งเดียว • ใช้ได้ 1 ใบต่อรายการ',
                      ),
                      if (priceSatang != null) ...[
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: coupon.discountFor(priceSatang!) > 0
                              ? () => Navigator.pop(context, coupon)
                              : null,
                          child: Text(
                            coupon.discountFor(priceSatang!) == 0
                                ? (coupon.status == 'Available'
                                      ? 'ยอดไม่ถึงขั้นต่ำ'
                                      : 'คูปองไม่พร้อมใช้')
                                : coupon.id == selectedId
                                ? 'เลือกอยู่'
                                : 'ใช้คูปองนี้',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
