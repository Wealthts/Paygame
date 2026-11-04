import 'package:flutter/material.dart';

import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/views/user/paygame_package.dart';
import 'package:frontend/views/user/receipt_screen.dart';
import 'package:frontend/views/user/rewards_screen.dart';

void main() {
  runApp(const GamePayApp());
}

class GamePayApp extends StatelessWidget {
  const GamePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GamePay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const GamePayShell(),
    );
  }
}

/// หน้าหลักทำหน้าที่เก็บ State กลางและส่งข้อมูลให้แต่ละหน้า
class GamePayShell extends StatefulWidget {
  const GamePayShell({super.key});

  @override
  State<GamePayShell> createState() => _GamePayShellState();
}

class _GamePayShellState extends State<GamePayShell> {
  int _index = 0;

  // แต้มเริ่มต้นสำหรับข้อมูลเดโม สามารถเปลี่ยนเป็น 0 ได้
  int _points = 1184;

  PaygameOrder? _latestOrder;

  final List<RewardHistory> _history = [
    RewardHistory(
      title: 'เติม ROV · GP-0042',
      date: '29 ต.ค.',
      amount: '+34',
      isEarned: true,
    ),
    RewardHistory(
      title: 'ใช้เป็นส่วนลด · GP-0042',
      date: '29 ต.ค.',
      amount: '−100',
      isEarned: false,
    ),
    RewardHistory(
      title: 'เติม Genshin · GP-0038',
      date: '25 ต.ค.',
      amount: '+53',
      isEarned: true,
    ),
    RewardHistory(
      title: 'โบนัสสมัครสมาชิก',
      date: '15 ก.ย.',
      amount: '+50',
      isEarned: true,
    ),
  ];

  void _handlePaymentCompleted(PaygameOrder order) {
    if (!order.success) return;

    setState(() {
      _latestOrder = order;
      _points = order.pointsBalance;

      final date = _dateText(order.createdAt);

      _history.insert(
        0,
        RewardHistory(
          title: 'เติม ${order.game.name} · ${order.id}',
          date: date,
          amount: '+${order.earnedPoints}',
          isEarned: true,
        ),
      );

      if (order.discountSatang > 0) {
        _history.insert(
          1,
          RewardHistory(
            title: 'ใช้แต้มเป็นส่วนลด · ${order.id}',
            date: date,
            amount: '−100',
            isEarned: false,
          ),
        );
      }

      // เปิดหน้าใบเสร็จหลังจากเติมสำเร็จ
      _index = 1;
    });
  }

  void _handleRedeem(RewardItem reward) {
    if (_points < reward.cost) return;

    setState(() {
      _points -= reward.cost;

      _history.insert(
        0,
        RewardHistory(
          title: 'แลก ${reward.name}',
          date: _dateText(DateTime.now()),
          amount: '−${reward.cost}',
          isEarned: false,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('แลก ${reward.name} สำเร็จ')),
    );
  }

  String _dateText(DateTime date) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          PaygamePackage(
            initialPoints: _points,
            onPaymentCompleted: _handlePaymentCompleted,
          ),
          ReceiptScreen(order: _latestOrder),
          RewardsScreen(
            points: _points,
            history: _history,
            onRedeem: _handleRedeem,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          setState(() => _index = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'เติมเกม',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'ใบเสร็จ',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'แลกรางวัล',
          ),
        ],
      ),
    );
  }
}