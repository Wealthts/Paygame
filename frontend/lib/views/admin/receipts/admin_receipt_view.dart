import 'package:flutter/material.dart';

import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/views/user/receipt_detail.dart';

/// Receipt row (based on receipts JOIN orders, users, payments)
/// Mock data for now, not connected to the API yet
class AdminReceiptItem {
  final String receiptNumber;
  final int orderId;
  final String username;
  final String gameName;
  final String packageName;
  final String playerUid;
  final String method;
  final double originalPrice;
  final double discountAmount;
  final double totalAmount;
  final DateTime issuedAt;

  const AdminReceiptItem({
    required this.receiptNumber,
    required this.orderId,
    required this.username,
    required this.gameName,
    required this.packageName,
    required this.playerUid,
    required this.method,
    required this.originalPrice,
    required this.discountAmount,
    required this.totalAmount,
    required this.issuedAt,
  });
}

class AdminReceiptsView extends StatefulWidget {
  const AdminReceiptsView({super.key});

  @override
  State<AdminReceiptsView> createState() => _AdminReceiptsViewState();
}

class _AdminReceiptsViewState extends State<AdminReceiptsView> {
  final TextEditingController _searchController = TextEditingController();
  String _range = 'All';

  static final List<AdminReceiptItem> _receipts = [
    AdminReceiptItem(
      receiptNumber: 'GP-20261111-0006',
      orderId: 6,
      username: 'Napat',
      gameName: 'ROV',
      packageName: '400 Coupons',
      playerUid: '1234567890',
      method: 'PromptPay QR',
      originalPrice: 350,
      discountAmount: 10,
      totalAmount: 340,
      issuedAt: DateTime(2026, 11, 11, 22, 41),
    ),
    AdminReceiptItem(
      receiptNumber: 'GP-20261111-0005',
      orderId: 5,
      username: 'Chalisa',
      gameName: 'Free Fire',
      packageName: '520 Diamonds',
      playerUid: '9876543210',
      method: 'e-Wallet',
      originalPrice: 199,
      discountAmount: 0,
      totalAmount: 201,
      issuedAt: DateTime(2026, 11, 11, 18, 5),
    ),
    AdminReceiptItem(
      receiptNumber: 'GP-20261110-0004',
      orderId: 4,
      username: 'Natthawat',
      gameName: 'Genshin Impact',
      packageName: '300 Crystals',
      playerUid: '800123456',
      method: 'PromptPay QR',
      originalPrice: 179,
      discountAmount: 20,
      totalAmount: 159,
      issuedAt: DateTime(2026, 11, 10, 20, 11),
    ),
    AdminReceiptItem(
      receiptNumber: 'GP-20261108-0002',
      orderId: 2,
      username: 'Napat',
      gameName: 'ROV',
      packageName: '90 Coupons',
      playerUid: '1234567890',
      method: 'Credit Card',
      originalPrice: 79,
      discountAmount: 0,
      totalAmount: 81,
      issuedAt: DateTime(2026, 11, 8, 9, 30),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminReceiptItem> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _receipts;
    return _receipts.where((r) {
      return r.receiptNumber.toLowerCase().contains(q) ||
          r.username.toLowerCase().contains(q) ||
          r.playerUid.contains(q) ||
          r.gameName.toLowerCase().contains(q);
    }).toList();
  }

  void _openReceipt(AdminReceiptItem r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReceiptPreviewSheet(receipt: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final total = _receipts.fold<double>(0, (s, r) => s + r.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Receipts')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ---------- Summary ----------
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                icon: Icons.receipt_long_outlined,
                label: 'Total receipts',
                value: '${_receipts.length}',
                color: AppColors.red,
              ),
              _StatCard(
                icon: Icons.payments_outlined,
                label: 'Total revenue',
                value: _baht(total),
                color: AppColors.success,
              ),
              const _StatCard(
                icon: Icons.today_outlined,
                label: 'Issued today',
                value: '2',
                color: AppColors.goldText,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---------- Search + date range ----------
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search receipt no. / user / UID / game',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final r in const ['Today', 'Last 7 days', 'All'])
                ChoiceChip(
                  label: Text(r),
                  selected: _range == r,
                  onSelected: (_) => setState(() => _range = r),
                  selectedColor: AppColors.red,
                  labelStyle: TextStyle(
                    color: _range == r ? AppColors.white : AppColors.inkMuted,
                  ),
                  backgroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.border),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ---------- Receipt list ----------
          Text(
            'Receipts (${items.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const _EmptyState(text: 'No receipts found')
          else
            for (final r in items) ...[
              _ReceiptTile(receipt: r, onTap: () => _openReceipt(r)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

// ======================================================================
// Single receipt card
// ======================================================================
class _ReceiptTile extends StatelessWidget {
  final AdminReceiptItem receipt;
  final VoidCallback onTap;

  const _ReceiptTile({required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.receiptNumber,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.username} · ${r.gameName} ${r.packageName}',
                      style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_formatDate(r.issuedAt)} · Order #${r.orderId}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _baht(r.totalAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _Pill(text: 'PAID', fg: AppColors.success, bg: AppColors.successBg),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// Bottom sheet: full receipt preview (same look as the user receipt)
// ======================================================================
class _ReceiptPreviewSheet extends StatelessWidget {
  final AdminReceiptItem receipt;
  const _ReceiptPreviewSheet({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          children: [
                            TextSpan(text: 'Game'),
                            TextSpan(text: 'Pay', style: TextStyle(color: AppColors.red)),
                            TextSpan(text: ' E-Receipt'),
                          ],
                        ),
                      ),
                      Spacer(),
                      _Pill(text: 'PAID', fg: AppColors.success, bg: AppColors.successBg),
                    ],
                  ),
                  const DashedDivider(),
                  _Line('Receipt no.', r.receiptNumber, bold: true),
                  _Line('Order', '#${r.orderId}'),
                  _Line('User', r.username),
                  _Line('Issued at', _formatDate(r.issuedAt)),
                  _Line('Game', r.gameName),
                  _Line('Package', r.packageName),
                  _Line('UID', r.playerUid, bold: true),
                  _Line('Method', r.method),
                  const DashedDivider(),
                  _Line('Price', _baht(r.originalPrice)),
                  _Line('Discount', '−${_baht(r.discountAmount)}', color: AppColors.red),
                  _Line('Total paid', _baht(r.totalAmount), bold: true, color: AppColors.red),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download PDF'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Small widgets used on this page
// ======================================================================
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  const _Pill({required this.text, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _Line(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.inkMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: color ?? AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.inkMuted),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

// ======================================================================
// Formatting helpers
// ======================================================================
String _baht(double v) {
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '฿$whole.${parts[1]}';
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year} · $hh:$mm';
}
