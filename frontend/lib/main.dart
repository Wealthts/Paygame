import 'package:flutter/material.dart';

import 'controllers/points_controller.dart';
import 'theme/app_theme.dart';
import 'views/receipt_screen.dart';
import 'views/rewards_screen.dart';

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
      home: const DemoShell(),
    );
  }
}

/// หน้าเดโมสำหรับสลับดู 2 หน้าที่รับผิดชอบ
/// (ตอนรวมกับงานเพื่อน ให้ย้าย 2 หน้านี้ไปใส่ใน navigation หลักของแอป)
class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  final _points = PointsController();
  int _index = 0;

  @override
  void dispose() {
    _points.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ReceiptScreen(onViewPoints: () => setState(() => _index = 1)),
      RewardsScreen(controller: _points),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
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
