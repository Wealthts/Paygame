import 'package:flutter/material.dart';

import '../controllers/points_controller.dart';
import '../models/point_transaction.dart';
import '../models/reward.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// หน้า Reward / Point System (MVC: ฝั่ง View)
class RewardsScreen extends StatelessWidget {
  final PointsController controller;

  const RewardsScreen({super.key, required this.controller});

  Future<void> _confirmRedeem(BuildContext context, Reward reward) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('ยืนยันการแลก', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('ใช้ ${Fmt.number(reward.pointsCost)} แต้ม แลก "${reward.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก', style: TextStyle(color: AppColors.inkMuted)),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('แลกเลย')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final success = controller.redeem(reward);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.success : AppColors.danger,
        content: Text(success ? 'แลกสำเร็จ! คูปองจะใช้ได้ในการเติมครั้งถัดไป' : 'แต้มไม่พอสำหรับรางวัลนี้'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _PointsHeader(controller: controller)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverList.list(
                  children: [
                    const _SectionTitle('แลกของรางวัล'),
                    const SizedBox(height: 10),
                    for (final r in controller.rewards) ...[
                      _RewardTile(
                        reward: r,
                        enabled: controller.canRedeem(r),
                        onRedeem: () => _confirmRedeem(context, r),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    const _SectionTitle('ความเคลื่อนไหวแต้ม'),
                    const SizedBox(height: 10),
                    _HistoryCard(items: controller.transactions),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PointsHeader extends StatelessWidget {
  final PointsController controller;
  const _PointsHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tier = controller.tier;
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
                      child: Text(
                        '${tier.name} MEMBER',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(color: AppColors.goldInk, fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(text: Fmt.number(controller.balance), style: const TextStyle(fontSize: 38)),
                      const TextSpan(text: '  แต้ม', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: controller.tierProgress,
                    minHeight: 8,
                    backgroundColor: AppColors.creamDeep,
                    color: AppColors.redDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tier.nextName == null
                      ? 'คุณอยู่ระดับสูงสุดแล้ว · เติมทุก ฿10 = 1 แต้ม'
                      : 'อีก ${Fmt.number(controller.pointsToNextTier)} แต้ม เลื่อนเป็น ${tier.nextName} · เติมทุก ฿10 = 1 แต้ม',
                  style: const TextStyle(fontSize: 12, color: AppColors.goldInk),
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
  final Reward reward;
  final bool enabled;
  final VoidCallback onRedeem;

  const _RewardTile({required this.reward, required this.enabled, required this.onRedeem});

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
              reward.tag,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(
                  'ใช้ ${Fmt.number(reward.pointsCost)} แต้ม',
                  style: const TextStyle(fontSize: 12, color: AppColors.goldText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: enabled ? onRedeem : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.inkMuted,
            ),
            child: Text(enabled ? 'แลก' : 'แต้มไม่พอ'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<PointTransaction> items;
  const _HistoryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == items.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].description, style: const TextStyle(fontSize: 14)),
                        Text(
                          Fmt.thaiShortDate(items[i].createdAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Fmt.pointsDelta(items[i].pointsDelta),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: items[i].isPositive ? AppColors.success : AppColors.danger,
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
