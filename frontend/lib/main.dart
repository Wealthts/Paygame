import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/paygame_controller.dart';
import 'models/paygame_models.dart';
import 'theme/app_theme.dart';
import 'views/user/home_view.dart';
import 'views/user/receipt_view.dart';
import 'views/user/history_view.dart';
import 'views/login.dart';
import 'views/user/game_detail_view.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PaygameController(),
      child: const GamePayApp(),
    ),
  );
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

class GamePayShell extends StatefulWidget {
  const GamePayShell({super.key});

  @override
  State<GamePayShell> createState() => _GamePayShellState();
}

class _GamePayShellState extends State<GamePayShell> {
  int _index = 0;
  PaygameOrder? _latestOrder;

  void _handlePaymentCompleted(PaygameOrder order) {
    if (!order.success) return;

    context.read<PaygameController>().addOrder(
      OrderModel(
        orderId: order.id,
        gameName: order.game.name,
        packageName: '${order.pack.quantity} ${order.game.unit}',
        playerUid: order.uid,
        serverCode: order.server,
        originalPrice: order.priceSatang / 100,
        discountAmount: order.discountSatang / 100,
        totalAmount: order.totalSatang / 100,
        paymentMethod: order.method.label,
        status: 'completed',
        earnedPoints: order.earnedPoints,
        pointsBalance: order.pointsBalance,
        createdAt: order.createdAt,
      ),
    );

    setState(() {
      _latestOrder = order;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeView(
            onPaymentCompleted: _handlePaymentCompleted,
            initialPoints: context.read<PaygameController>().userPointsBalance,
          ),
          ReceiptScreen(order: _latestOrder),
          const RewardsScreen(),
          const LoginScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          setState(() => _index = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าแรก',
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
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'เข้าสู่ระบบ',
          ),
        ],
      ),
    );
  }
}
