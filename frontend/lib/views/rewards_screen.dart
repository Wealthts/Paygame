import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// หน้า Reward / Point System (UI อย่างเดียว ข้อมูลเป็นตัวอย่าง)
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _PointsHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            sliver: SliverList.list(
              children: const [
                _SectionTitle('แลกของรางวัล'),
                SizedBox(height: 10),
                _RewardTile(tag: '฿20', name: 'ส่วนลด 20 บาท (ทุกเกม)', cost: '200'),
                SizedBox(height: 10),
                _RewardTile(tag: '฿50', name: 'ส่วนลด 50 บาท (ขั้นต่ำ ฿300)', cost: '450'),
                SizedBox(height: 10),
                _RewardTile(tag: '5%', name: 'คูปองลด 5% ไม่จำกัดยอด', cost: '800'),
                SizedBox(height: 10),
                _RewardTile(tag: '฿150', name: 'ส่วนลด 150 บาท (ขั้นต่ำ ฿1,000)', cost: '1,500', enough: false),
                SizedBox(height: 18),
                _SectionTitle('ความเคลื่อนไหวแต้ม'),
                SizedBox(height: 10),
                _HistoryCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsHeader extends StatelessWidget {
  const _PointsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 18, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แต้มสะสม & รางวัล',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.white),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: AppColors.redDark, offset: Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'แต้มที่ใช้ได้',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.goldInk),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.redDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'GOLD MEMBER',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(color: AppColors.goldInk, fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(text: '1,184', style: TextStyle(fontSize: 38)),
                      TextSpan(text: '  แต้ม', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.59,
                    minHeight: 8,
                    backgroundColor: AppColors.creamDeep,
                    color: AppColors.redDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'อีก 816 แต้ม เลื่อนเป็น Platinum · เติมทุก ฿10 = 1 แต้ม',
                  style: TextStyle(fontSize: 12, color: AppColors.goldInk),
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
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600));
}

class _RewardTile extends StatelessWidget {
  final String tag;
  final String name;
  final String cost;
  final bool enough;

  const _RewardTile({required this.tag, required this.name, required this.cost, this.enough = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.red, width: 1.5),
            ),
            child: Text(
              tag,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text('ใช้ $cost แต้ม', style: const TextStyle(fontSize: 12, color: AppColors.goldText)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: enough ? () {} : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
  const _HistoryCard();

  static const _items = [
    ('เติม ROV · GP-0042', '29 ต.ค.', '+34', true),
    ('ใช้เป็นส่วนลด · GP-0042', '29 ต.ค.', '−100', false),
    ('เติม Genshin · GP-0038', '25 ต.ค.', '+53', true),
    ('โบนัสสมัครสมาชิก', '15 ก.ย.', '+50', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == _items.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_items[i].$1, style: const TextStyle(fontSize: 14)),
                        Text(_items[i].$2, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                  Text(
                    _items[i].$3,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _items[i].$4 ? AppColors.success : AppColors.danger,
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
