import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'game_detail_view.dart';
import 'receipt_detail.dart';

/// ใบเสร็จจะแสดงข้อมูลจากคำสั่งซื้อล่าสุดที่ชำระเงินสำเร็จ
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.order});

  final PaygameOrder? order;

  String number(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );

  String money(int satang) {
    final whole = satang ~/ 100;
    final decimal = satang % 100;
    return '฿${number(whole)}.${decimal.toString().padLeft(2, '0')}';
  }

  String dateText(DateTime date) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year + 543} '
        '· ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentOrder = order;

    return Scaffold(
      backgroundColor: AppColors.red,
      appBar: AppBar(
        title: const Text('ใบเสร็จ'),
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: currentOrder == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: AppColors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'ยังไม่มีใบเสร็จ',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'ใบเสร็จจะแสดงที่หน้านี้หลังจากเติมเกมสำเร็จ',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.peach),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  const _SuccessHeader(),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                children: [
                                  TextSpan(text: 'Game'),
                                  TextSpan(
                                    text: 'Pay',
                                    style: TextStyle(color: AppColors.red),
                                  ),
                                  TextSpan(text: ' E-Receipt'),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'SUCCESS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const DashedDivider(),
                        _Line('เลขที่คำสั่งซื้อ', currentOrder.id, bold: true),
                        _Line('วันที่', dateText(currentOrder.createdAt)),
                        _Line('เกม', currentOrder.game.name),
                        _Line(
                          'แพ็กเกจ',
                          '${number(currentOrder.pack.quantity)} '
                              '${currentOrder.game.unit}',
                        ),
                        _Line('UID', currentOrder.uid, bold: true),
                        if (currentOrder.server != null)
                          _Line('เซิร์ฟเวอร์', currentOrder.server!),
                        _Line('ช่องทาง', currentOrder.method.label),
                        const DashedDivider(),
                        _Line('ราคาแพ็กเกจ', money(currentOrder.priceSatang)),
                        _Line(
                          'ส่วนลดจากแต้ม',
                          '−${money(currentOrder.discountSatang)}',
                          valueColor: AppColors.red,
                        ),
                        _Line('ค่าธรรมเนียม', money(currentOrder.feeSatang)),
                        const Divider(),
                        _Line(
                          'ยอดชำระ',
                          money(currentOrder.totalSatang),
                          bold: true,
                          valueColor: AppColors.red,
                          large: true,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.gold,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_outline_rounded,
                                color: AppColors.goldText,
                                size: 30,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ได้รับ +${currentOrder.earnedPoints} แต้ม',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.goldText,
                                      ),
                                    ),
                                    Text(
                                      'แต้มคงเหลือ '
                                      '${number(currentOrder.pointsBalance)} แต้ม',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: AppColors.gold,
          child: Icon(Icons.check_rounded, size: 42, color: AppColors.redDark),
        ),
        SizedBox(height: 12),
        Text(
          'เติมเกมสำเร็จ!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'บันทึกข้อมูลคำสั่งซื้อเรียบร้อยแล้ว',
          style: TextStyle(fontSize: 14, color: AppColors.peach),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(
    this.label,
    this.value, {
    this.bold = false,
    this.valueColor,
    this.large = false,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: large ? 16 : 14,
                color: AppColors.inkMuted,
                fontWeight: large ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: large ? 18 : 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: valueColor ?? AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
