import 'package:flutter/material.dart';

import 'package:frontend/theme/app_colors.dart';

/// Per-user point balance (SUM(points_delta) from point_transactions)
class AdminPointBalance {
  final String username;
  final String displayName;
  final int balance;
  final int earnedTotal;

  const AdminPointBalance({
    required this.username,
    required this.displayName,
    required this.balance,
    required this.earnedTotal,
  });
}

/// Single point transaction (based on point_transactions)
class AdminPointTx {
  final int id;
  final String username;
  final int? orderId;
  final String type; // earn | redeem | adjust
  final int pointsDelta;
  final String note;
  final DateTime createdAt;

  const AdminPointTx({
    required this.id,
    required this.username,
    required this.orderId,
    required this.type,
    required this.pointsDelta,
    required this.note,
    required this.createdAt,
  });
}

class AdminPointsView extends StatefulWidget {
  const AdminPointsView({super.key});

  @override
  State<AdminPointsView> createState() => _AdminPointsViewState();
}

class _AdminPointsViewState extends State<AdminPointsView> {
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'all';

  // ---------- Mock data (not connected to the API yet) ----------
  static const List<AdminPointBalance> _balances = [
    AdminPointBalance(username: 'Napat', displayName: 'Mocha', balance: 1184, earnedTotal: 1284),
    AdminPointBalance(username: 'Chalisa', displayName: 'Film', balance: 420, earnedTotal: 470),
    AdminPointBalance(username: 'Natthawat', displayName: 'Test User', balance: 65, earnedTotal: 265),
  ];

  static final List<AdminPointTx> _transactions = [
    AdminPointTx(
      id: 9,
      username: 'Napat',
      orderId: 6,
      type: 'earn',
      pointsDelta: 34,
      note: 'Top-up ROV 400 Coupons',
      createdAt: DateTime(2026, 11, 11, 22, 41),
    ),
    AdminPointTx(
      id: 8,
      username: 'Napat',
      orderId: 6,
      type: 'redeem',
      pointsDelta: -100,
      note: 'Used as discount',
      createdAt: DateTime(2026, 11, 11, 22, 40),
    ),
    AdminPointTx(
      id: 7,
      username: 'Chalisa',
      orderId: 5,
      type: 'earn',
      pointsDelta: 20,
      note: 'Top-up Free Fire 520 Diamonds',
      createdAt: DateTime(2026, 11, 11, 18, 5),
    ),
    AdminPointTx(
      id: 6,
      username: 'Natthawat',
      orderId: null,
      type: 'redeem',
      pointsDelta: -200,
      note: 'Redeemed coupon REWARD20',
      createdAt: DateTime(2026, 11, 10, 21, 0),
    ),
    AdminPointTx(
      id: 5,
      username: 'Chalisa',
      orderId: null,
      type: 'adjust',
      pointsDelta: 50,
      note: 'Sign-up bonus',
      createdAt: DateTime(2026, 11, 9, 10, 0),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminPointTx> get _filteredTx {
    final q = _searchController.text.trim().toLowerCase();
    return _transactions.where((t) {
      final matchType = _typeFilter == 'all' || t.type == _typeFilter;
      final matchSearch = q.isEmpty ||
          t.username.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q) ||
          (t.orderId?.toString() ?? '').contains(q);
      return matchType && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final earned = _transactions
        .where((t) => t.pointsDelta > 0)
        .fold<int>(0, (s, t) => s + t.pointsDelta);
    final spent = _transactions
        .where((t) => t.pointsDelta < 0)
        .fold<int>(0, (s, t) => s - t.pointsDelta);
    final inSystem = _balances.fold<int>(0, (s, b) => s + b.balance);
    final txs = _filteredTx;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Points')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.goldInk,
        icon: const Icon(Icons.tune),
        label: const Text('Adjust points'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          // ---------- Summary ----------
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                icon: Icons.add_circle_outline,
                label: 'Points issued',
                value: _num(earned),
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
                value: _num(inSystem),
                color: AppColors.goldText,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ---------- User balances ----------
          const _SectionTitle(icon: Icons.leaderboard_outlined, text: 'User balances'),
          const SizedBox(height: 10),
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
            children: [
              for (final f in const [
                ('all', 'All'),
                ('earn', 'Earned'),
                ('redeem', 'Spent'),
                ('adjust', 'Admin adjust'),
              ])
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No transactions found', style: TextStyle(color: AppColors.inkMuted)),
              ),
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
    final isTop = rank == 1;
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
                Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    final (IconData icon, String label, Color fg, Color bg) = switch (tx.type) {
      'earn' => (Icons.arrow_downward_rounded, 'Earned', AppColors.success, AppColors.successBg),
      'redeem' => (Icons.arrow_upward_rounded, 'Spent', AppColors.danger, AppColors.dangerBg),
      _ => (Icons.tune, 'Admin adjust', AppColors.goldText, AppColors.creamDeep),
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
              Text(label, style: TextStyle(fontSize: 11, color: fg)),
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
