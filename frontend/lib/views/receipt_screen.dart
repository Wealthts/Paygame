import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'widgets/dashed_divider.dart';

/// หน้า E-Receipt (UI อย่างเดียว ข้อมูลเป็นตัวอย่าง)
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.red,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            const _SuccessHeader(),
            const SizedBox(height: 20),
            const _ReceiptCard(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.goldInk,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text('บันทึกใบเสร็จ'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white, width: 2),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('กลับหน้าแรก', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.goldLight, width: 4),
          ),
          child: const Icon(Icons.check_rounded, size: 42, color: AppColors.redDark),
        ),
        const SizedBox(height: 12),
        const Text(
          'เติมเงินสำเร็จ!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'คูปองเข้าบัญชีเกมเรียบร้อยแล้ว',
          style: TextStyle(fontSize: 14, color: AppColors.peach),
        ),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(text: 'Game'),
                    TextSpan(text: 'Pay', style: TextStyle(color: AppColors.red)),
                    TextSpan(text: ' E-Receipt'),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'SUCCESS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                ),
              ),
            ],
          ),
          const DashedDivider(),
          const _Line('เลขที่ใบเสร็จ', 'GP-20261029-0042', bold: true),
          const _Line('วันที่', '29 ต.ค. 2569 · 16:42'),
          const _Line('เกม', 'ROV'),
          const _Line('แพ็กเกจ', '400 คูปอง'),
          const _Line('UID', '1234567890', bold: true),
          const _Line('ช่องทาง', 'QR พร้อมเพย์'),
          const DashedDivider(),
          const _Line('ราคา', '฿350.00'),
          const _Line('ส่วนลดแต้ม (100 แต้ม)', '−฿10.00', valueColor: AppColors.red),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text('ยอดชำระ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Spacer(),
                Text(
                  '฿340.00',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_outline_rounded, color: AppColors.goldText, size: 30),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ได้รับ +34 แต้ม',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.goldText),
                    ),
                    Text('แต้มคงเหลือ 1,184 แต้ม', style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _Line(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.inkMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
                color: valueColor ?? AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
