import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/controllers/paygame_controller.dart';
import 'package:frontend/models/paygame_models.dart';

import 'package:frontend/theme/app_theme.dart';

import 'package:frontend/views/login_view.dart';
import 'package:frontend/views/user/home_view.dart';
import 'package:frontend/views/user/purchase_history_view.dart';
import 'package:frontend/views/user/reward_history_view.dart';
import 'package:frontend/views/user/game_detail_view.dart';

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
  int currentIndex = 0;
  final List<PaygameOrder> orders = [];

  void handlePaymentCompleted(PaygameOrder order) {
    // Stop if payment was unsuccessful.
    if (!order.success) return;

    // Convert payment data into the history model.
    final orderModel = OrderModel(
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
    );

    // Save the completed order.
    context.read<PaygameController>().addOrder(orderModel);

    // Update local order history and navigate to history.
    setState(() {
      orders.insert(0, order);
      currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userPoints = context.watch<PaygameController>().userPointsBalance;

    return Scaffold(
      // Main page content.
      body: IndexedStack(
        index: currentIndex,
        children: [
          // Home Page
          HomeView(
            onPaymentCompleted: handlePaymentCompleted,
            initialPoints: userPoints,
          ),

          // Purchase History
          PurchaseHistoryView(orders: orders),

          // Reward History
          const RewardsScreen(),

          // Login Page
          const LoginScreen(),
        ],
      ),

      // Bottom Navigation.
      bottomNavigationBar: buildNavigationBar(),
    );
  }

  // Navigation bar builder.
  Widget buildNavigationBar() {
    return NavigationBar(
      selectedIndex: currentIndex,

      // Change the selected page.
      onDestinationSelected: (destinationIndex) {
        setState(() {
          currentIndex = destinationIndex;
        });
      },

      // Navigation destinations.
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),

        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'History',
        ),

        NavigationDestination(
          icon: Icon(Icons.card_giftcard_outlined),
          selectedIcon: Icon(Icons.card_giftcard),
          label: 'Rewards',
        ),

        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Login',
        ),
      ],
    );
  }
}
