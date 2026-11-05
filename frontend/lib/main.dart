import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/paygame_controller.dart';
import 'models/paygame_models.dart';
import 'theme/app_theme.dart';
import 'views/user/home_view.dart';
import 'views/user/purchase_history_view.dart';
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
  final _orders = <PaygameOrder>[];

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
      _orders.insert(0, order);
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
            initialPoints: context.watch<PaygameController>().userPointsBalance,
          ),
          PurchaseHistoryView(orders: _orders),
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
            label: 'ประวัติ',
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
