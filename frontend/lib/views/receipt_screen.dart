import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/receipt_controller.dart';
import '../models/receipt.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'widgets/dashed_divider.dart';

/// หน้า E-Receipt (MVC: ฝั่ง View)
class ReceiptScreen extends StatefulWidget {
  final String orderCode;
  final VoidCallback? onViewPoints;

  const ReceiptScreen({super.key, this.orderCode = 'GP-0042', this.onViewPoints});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _controller = ReceiptController();

  @override
  void initState() {
    super.initState();
    _controller.load(widget.orderCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveReceipt(Receipt r) async {
    await Clipboard.setData(ClipboardData(text: _controller.toShareText(r)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอกรายละเอียดใบเสร็จแล้ว')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.red,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final r = _controller.receipt;
            if (_controller.isLoading || r == null) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              children: [
                _SuccessHeader(success: r.isSuccess),
                const SizedBox(height: 20),
                _ReceiptCard(receipt: r),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _saveReceipt(r),
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
                  onPressed: widget.onViewPoints,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.white, width: 2),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('ดูแต้มสะสม', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  final bool success;
  const _SuccessHeader({required this.success});

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
          child: Icon(
            success ? Icons.check_rounded : Icons.close_rounded,
            size: 42,
            color: AppColors.redDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          success ? 'เติมเงินสำเร็จ!' : 'เติมเงินไม่สำเร็จ',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.white),
        ),
        const SizedBox(height: 4),
        Text(
          success ? 'คูปองเข้าบัญชีเกมเรียบร้อยแล้ว' : 'ระบบไม่ได้ตัดเงินจากบัญชีของคุณ',
          style: const TextStyle(fontSize: 14, color: AppColors.peach),
        ),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  const _ReceiptCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final r = receipt;
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
              _StatusPill(success: r.isSuccess),
            ],
          ),
          const DashedDivider(),
          _Line('เลขที่ใบเสร็จ', r.receiptNumber, bold: true),
          _Line('วันที่', Fmt.thaiDateTime(r.issuedAt)),
          _Line('เกม', r.gameName),
          _Line('แพ็กเกจ', r.packageName),
          _Line('UID', r.playerUid, bold: true),
          _Line('ช่องทาง', r.paymentMethod),
          const DashedDivider(),
          _Line('ราคา', Fmt.baht(r.originalPrice)),
          if (r.discountAmount > 0)
            _Line(
              'ส่วนลดแต้ม (${Fmt.number(r.pointsUsed)} แต้ม)',
              '−${Fmt.baht(r.discountAmount)}',
              valueColor: AppColors.red,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Text('ยอดชำระ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  Fmt.baht(r.totalAmount),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (r.isSuccess) _PointsEarnedBox(earned: r.pointsEarned, balance: r.pointsBalanceAfter),
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

class _StatusPill extends StatelessWidget {
  final bool success;
  const _StatusPill({required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: success ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        success ? 'SUCCESS' : 'FAILED',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: success ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}

class _PointsEarnedBox extends StatelessWidget {
  final int earned;
  final int balance;
  const _PointsEarnedBox({required this.earned, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline_rounded, color: AppColors.goldText, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ได้รับ +${Fmt.number(earned)} แต้ม',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.goldText),
              ),
              Text(
                'แต้มคงเหลือ ${Fmt.number(balance)} แต้ม',
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
