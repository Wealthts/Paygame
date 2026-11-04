import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class RewardItem {
  const RewardItem({
    required this.tag,
    required this.name,
    required this.cost,
    this.description = '',
  });

  final String tag;
  final String name;
  final int cost;
  final String description;
}

class RewardHistory {
  const RewardHistory({
    required this.title,
    required this.date,
    required this.amount,
    required this.isEarned,
  });

  final String title;
  final String date;
  final String amount;
  final bool isEarned;
}

/// หน้าแต้มสะสมรับข้อมูลจาก State กลางของแอป
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({
    super.key,
    required this.points,
    required this.history,
    required this.onRedeem,
  });

  final int points;
  final List<RewardHistory> history;
  final ValueChanged<RewardItem> onRedeem;

  static const List<RewardItem> _rewards = [
    RewardItem(
      tag: '฿20',
      name: 'ส่วนลด 20 บาท (ทุกเกม)',
      cost: 200,
    ),
    RewardItem(
      tag: '฿50',
      name: 'ส่วนลด 50 บาท (ขั้นต่ำ ฿300)',
      cost: 450,
    ),
    RewardItem(
      tag: '5%',
      name: 'คูปองลด 5% ไม่จำกัดยอด',
      cost: 800,
    ),
    RewardItem(
      tag: '฿150',
      name: 'ส่วนลด 150 บาท (ขั้นต่ำ ฿1,000)',
      cost: 1500,
    ),
  ];

  String _number(int value) => value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );

  void _confirmRedeem(BuildContext context, RewardItem reward) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการแลกรางวัล'),
        content: Text(
          'ต้องการแลก ${reward.name} '
          'ใช้ ${_number(reward.cost)} แต้มใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onRedeem(reward);
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _PointsHeader(
              points: points,
              number: _number,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SectionTitle('แลกของรางวัล'),
                const SizedBox(height: 10),
                for (final reward in _rewards) ...[
                  _RewardTile(
                    reward: reward,
                    enough: points >= reward.cost,
                    onPressed: () => _confirmRedeem(context, reward),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                const _SectionTitle('ความเคลื่อนไหวแต้ม'),
                const SizedBox(height: 10),
                _HistoryCard(history: history),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsHeader extends StatelessWidget {
  const _PointsHeader({
    required this.points,
    required this.number,
  });

  final int points;
  final String Function(int) number;

  @override
  Widget build(BuildContext context) {
    final progress = (points / 2000).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        22,
      ),
      decoration: const BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แต้มสะสม & รางวัล',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.redDark,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'แต้มที่ใช้ได้',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldInk,
                      ),
                    ),
                    Spacer(),
                    _MemberLabel(),
                  ],
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: AppColors.goldInk,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: number(points),
                        style: const TextStyle(fontSize: 38),
                      ),
                      const TextSpan(
                        text: '  แต้ม',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.creamDeep,
                    color: AppColors.redDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  points >= 2000
                      ? 'คุณอยู่ในระดับ Platinum'
                      : 'อีก ${number(2000 - points)} แต้ม '
                          'เลื่อนเป็น Platinum · เติมทุก ฿10 = 1 แต้ม',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.goldInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberLabel extends StatelessWidget {
  const _MemberLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.redDark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'GOLD MEMBER',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.reward,
    required this.enough,
    required this.onPressed,
  });

  final RewardItem reward;
  final bool enough;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.red,
                width: 1.5,
              ),
            ),
            child: Text(
              reward.tag,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'ใช้ ${reward.cost} แต้ม',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.goldText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: enough ? onPressed : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.inkMuted,
            ),
            child: Text(enough ? 'แลก' : 'แต้มไม่พอ'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});

  final List<RewardHistory> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('ยังไม่มีประวัติแต้ม'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < history.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == history.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(
                          color: AppColors.divider,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history[i].title,
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          history[i].date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    history[i].amount,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: history[i].isEarned
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}