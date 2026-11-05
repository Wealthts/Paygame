import 'package:flutter/material.dart';
import 'package:frontend/controllers/paygame_controller.dart';
import 'package:frontend/models/paygame_models.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  static const List<RewardItem> _rewards = [
    RewardItem(id: 'r1', tag: '฿20', name: 'ส่วนลด 20 บาท (ทุกเกม)', cost: 200),
    RewardItem(
      id: 'r2',
      tag: '฿50',
      name: 'ส่วนลด 50 บาท (ขั้นต่ำ ฿300)',
      cost: 450,
    ),
    RewardItem(id: 'r3', tag: '5%', name: 'คูปองลด 5% ไม่จำกัดยอด', cost: 800),
    RewardItem(
      id: 'r4',
      tag: '฿150',
      name: 'ส่วนลด 150 บาท (ขั้นต่ำ ฿1,000)',
      cost: 1500,
    ),
  ];

  void _confirmRedeem(
    BuildContext context,
    PaygameController controller,
    RewardItem reward,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการแลกรางวัล'),
        content: Text(
          'ต้องการแลก ${reward.name} ใช้ ${reward.cost} แต้มใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final success = controller.redeemReward(reward);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'แลก ${reward.name} สำเร็จ'
                        : 'แต้มสะสมไม่เพียงพอ',
                  ),
                  backgroundColor: success
                      ? AppColors.success
                      : AppColors.danger,
                ),
              );
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaygameController>();
    final points = controller.userPointsBalance;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'แต้มที่ใช้ได้',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldInk,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$points แต้ม',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'แลกของรางวัล',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                for (final reward in _rewards) ...[
                  Container(
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
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reward.tag,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
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
                        FilledButton(
                          onPressed: points >= reward.cost
                              ? () =>
                                    _confirmRedeem(context, controller, reward)
                              : null,
                          child: Text(
                            points >= reward.cost ? 'แลก' : 'แต้มไม่พอ',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 16),
                const Text(
                  'ความเคลื่อนไหวแต้ม',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      for (final item in controller.pointHistory)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.title),
                          subtitle: item.date.isEmpty ? null : Text(item.date),
                          trailing: Text(
                            item.amount,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.isEarned
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
