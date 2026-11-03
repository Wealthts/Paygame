import 'package:flutter/material.dart';

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

/// หน้าเดโมสำหรับสลับดู 2 หน้า (UI อย่างเดียว)
class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [ReceiptScreen(), RewardsScreen()],
      ),
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
