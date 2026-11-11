import 'package:flutter/material.dart';

import 'package:frontend/services/admin_report_service.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/views/user/receipt_detail.dart';

class AdminReceiptsView extends StatefulWidget {
  const AdminReceiptsView({super.key});

  @override
  State<AdminReceiptsView> createState() => _AdminReceiptsViewState();
}

class _AdminReceiptsViewState extends State<AdminReceiptsView> {
  final TextEditingController _searchController = TextEditingController();
  String _range = 'All';

  List<AdminReceiptItem> _receipts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminReportService.fetchReceipts();
      if (!mounted) return;
      setState(() {
        _receipts = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  bool _inRange(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case 'Today':
        return !d.isBefore(today);
      case 'Last 7 days':
        return !d.isBefore(today.subtract(const Duration(days: 6)));
      default:
        return true;
    }
  }

  List<AdminReceiptItem> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _receipts.where((r) {
      final matchSearch = q.isEmpty ||
          r.receiptNumber.toLowerCase().contains(q) ||
          r.username.toLowerCase().contains(q) ||
          r.playerUid.toLowerCase().contains(q) ||
          r.gameName.toLowerCase().contains(q);
      return matchSearch && _inRange(r.issuedAt);
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Receipts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.red));
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    final items = _filtered;
    final total = _receipts.fold<double>(0, (s, r) => s + r.totalAmount);
    final now = DateTime.now();
    final todayCount = _receipts
        .where((r) =>
            r.issuedAt.year == now.year &&
            r.issuedAt.month == now.month &&
            r.issuedAt.day == now.day)
        .length;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.red,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              _StatCard(
                icon: Icons.today_outlined,
                label: 'Issued today',
                value: '$todayCount',
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
            _EmptyState(
              text: _receipts.isEmpty
                  ? 'No receipts yet. Receipts appear after an admin approves a payment.'
                  : 'No receipts found',
            )
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
                  _StatusPill(status: r.paymentStatus),
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
      child: SingleChildScrollView(
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
                      _StatusPill(status: r.paymentStatus),
                    ],
                  ),
                  const DashedDivider(),
                  _Line('Receipt no.', r.receiptNumber, bold: true),
                  _Line('Order', '#${r.orderId}'),
                  _Line('User', '${r.displayName} (@${r.username})'),
                  _Line('Issued at', _formatDate(r.issuedAt)),
                  _Line('Game', r.gameName),
                  _Line('Package', r.packageName),
                  _Line('UID', r.playerUid, bold: true),
                  if (r.serverCode != null) _Line('Server', r.serverCode!),
                  _Line('Method', _methodLabel(r.method)),
                  const DashedDivider(),
                  _Line('Price', _baht(r.originalPrice)),
                  if (r.couponCode != null) _Line('Coupon', r.couponCode!),
                  if (r.spentPoints > 0) _Line('Points used', '${r.spentPoints} pts'),
                  _Line('Discount', '−${_baht(r.discountAmount)}', color: AppColors.red),
                  _Line('Fee', _baht(r.feeAmount)),
                  _Line('Total paid', _baht(r.totalAmount), bold: true, color: AppColors.red),
                ],
              ),
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

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final paid = status.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: paid ? AppColors.successBg : AppColors.creamDeep,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: paid ? AppColors.success : AppColors.goldText,
        ),
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
          const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.inkMuted),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.danger),
            const SizedBox(height: 8),
            const Text(
              'Could not load receipts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Formatting helpers
// ======================================================================
String _baht(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '฿$whole.${parts[1]}';
}

String _methodLabel(String method) {
  switch (method.toLowerCase()) {
    case 'qr':
      return 'PromptPay QR';
    case 'wallet':
      return 'e-Wallet';
    case 'card':
      return 'Credit / Debit card';
    default:
      return method;
  }
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
