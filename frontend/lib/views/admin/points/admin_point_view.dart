import 'package:flutter/material.dart';

import 'package:frontend/services/admin_report_service.dart';
import 'package:frontend/theme/app_colors.dart';

class AdminPointsView extends StatefulWidget {
  const AdminPointsView({super.key});

  @override
  State<AdminPointsView> createState() => _AdminPointsViewState();
}

class _AdminPointsViewState extends State<AdminPointsView> {
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'all';

  List<AdminPointBalance> _balances = [];
  List<AdminPointTx> _transactions = [];
  bool _loading = true;
  String? _error;

  // value used in point_transactions.type -> chip label
  static const List<(String, String)> _filters = [
    ('all', 'All'),
    ('earn', 'Earn'),
    ('spend', 'Spend'),
    ('redeem', 'Redeem'),
    ('refund', 'Refund'),
  ];

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
      final results = await Future.wait([
        AdminReportService.fetchPointBalances(),
        AdminReportService.fetchPointHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _balances = results[0] as List<AdminPointBalance>;
        _transactions = results[1] as List<AdminPointTx>;
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

  List<AdminPointTx> get _filteredTx {
    final q = _searchController.text.trim().toLowerCase();
    return _transactions.where((t) {
      final matchType = _typeFilter == 'all' || t.type.toLowerCase() == _typeFilter;
      final matchSearch = q.isEmpty ||
          t.username.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q) ||
          (t.orderId?.toString() ?? '').contains(q);
      return matchType && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Points'),
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

    // Summary numbers all come from point_transactions, so they always add up:
    // Outstanding = Issued - Spent
    var issued = 0;
    var spent = 0;
    var refunded = 0;
    for (final t in _transactions) {
      if (t.type.toLowerCase() == 'refund') {
        refunded += t.pointsDelta;
      } else if (t.pointsDelta > 0) {
        issued += t.pointsDelta;
      } else {
        spent -= t.pointsDelta;
      }
    }
    spent -= refunded; // refunded points were given back, so they are not "spent"
    final outstanding = issued - spent;
    final txs = _filteredTx;

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
                icon: Icons.add_circle_outline,
                label: 'Points issued',
                value: _num(issued),
                color: AppColors.success,
              ),
              _StatCard(
                icon: Icons.remove_circle_outline,
                label: 'Points spent',
                value: _num(spent),
                color: AppColors.danger,
              ),
              _StatCard(
                icon: Icons.stars_rounded,
                label: 'Outstanding points',
                value: _num(outstanding),
                color: AppColors.goldText,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------- User balances ----------
          const _SectionTitle(icon: Icons.leaderboard_outlined, text: 'User balances'),
          const SizedBox(height: 10),
          if (_balances.isEmpty)
            const _EmptyBox(text: 'No users yet')
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _balances.length; i++)
                    _BalanceRow(
                      rank: i + 1,
                      item: _balances[i],
                      showDivider: i != _balances.length - 1,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ---------- Point transactions ----------
          const _SectionTitle(icon: Icons.history, text: 'Point transactions'),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search user / note / order no.',
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
            runSpacing: 8,
            children: [
              for (final f in _filters)
                ChoiceChip(
                  label: Text(f.$2),
                  selected: _typeFilter == f.$1,
                  onSelected: (_) => setState(() => _typeFilter = f.$1),
                  selectedColor: AppColors.red,
                  labelStyle: TextStyle(
                    color: _typeFilter == f.$1 ? AppColors.white : AppColors.inkMuted,
                  ),
                  backgroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.border),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (txs.isEmpty)
            _EmptyBox(
              text: _transactions.isEmpty ? 'No point transactions yet' : 'No transactions found',
            )
          else
            for (final t in txs) ...[
              _TxTile(tx: t),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

// ======================================================================
// One user's balance row
// ======================================================================
class _BalanceRow extends StatelessWidget {
  final int rank;
  final AdminPointBalance item;
  final bool showDivider;

  const _BalanceRow({required this.rank, required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1 && item.balance > 0;
    final name = item.displayName.isEmpty ? item.username : item.displayName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isTop ? AppColors.gold : AppColors.creamDeep,
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isTop ? AppColors.goldInk : AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '@${item.username} · Lifetime ${_num(item.earnedTotal)} pts',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.gold),
            ),
            child: Text(
              '${_num(item.balance)} pts',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.goldText),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Single transaction card
// ======================================================================
class _TxTile extends StatelessWidget {
  final AdminPointTx tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final positive = tx.pointsDelta >= 0;
    final (IconData icon, Color fg, Color bg) = switch (tx.type.toLowerCase()) {
      'earn' => (Icons.arrow_downward_rounded, AppColors.success, AppColors.successBg),
      'refund' => (Icons.undo_rounded, AppColors.success, AppColors.successBg),
      'spend' => (Icons.arrow_upward_rounded, AppColors.danger, AppColors.dangerBg),
      'redeem' => (Icons.confirmation_number_outlined, AppColors.danger, AppColors.dangerBg),
      _ => (Icons.tune, AppColors.goldText, AppColors.creamDeep),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: fg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.note, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${tx.username}'
                  '${tx.orderId != null ? ' · Order #${tx.orderId}' : ''}'
                  ' · ${_formatDate(tx.createdAt)}',
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
                '${positive ? '+' : '−'}${_num(tx.pointsDelta.abs())}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: positive ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(height: 2),
              Text(tx.type, style: TextStyle(fontSize: 11, color: fg)),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Small widgets
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.red),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: AppColors.inkMuted)),
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
              'Could not load points',
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
String _num(int v) => v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year} · $hh:$mm';
}
