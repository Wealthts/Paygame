import 'package:flutter/material.dart';
import 'views/user/coupons_view.dart';
import 'package:frontend/views/user/game_detail_view.dart';
import 'package:provider/provider.dart';

import 'package:frontend/controllers/paygame_controller.dart';
import 'package:frontend/models/paygame_models.dart';
import 'package:frontend/theme/app_theme.dart';

import 'package:frontend/views/login_view.dart';
import 'package:frontend/views/admin/admin_shell_view.dart';
import 'package:frontend/views/user/paygame_shell_view.dart';
import 'package:frontend/views/user/purchase_history_view.dart';
import 'package:frontend/views/user/reward_history_view.dart';

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
    context.read<PaygameController>().refreshWallet();
    if (!order.success) {
      setState(() => currentIndex = 1);
      return;
    }

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
      spentPoints: order.spentPoints,
      couponId: order.couponId,
    );

    context.read<PaygameController>().addOrder(orderModel);

    setState(() {
      orders.insert(0, order);
      currentIndex = 1;
    });
  }

  // Logout
  Future<void> handleLogout() async {
    try {
      await context.read<PaygameController>().logout();

      if (!mounted) return;

      setState(() {
        currentIndex = 4;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logout successful')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaygameController>();

    if (controller.authToken != null && controller.currentRole == 'admin') {
      return AdminShellView(
        onLogout: () => context.read<PaygameController>().logout(),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomeView(
            onPaymentCompleted: handlePaymentCompleted,
            initialPoints: controller.userPointsBalance,
          ),

          PurchaseHistoryView(
            key: ValueKey(
              '${controller.currentUserId}-$currentIndex-${orders.length}',
            ),
            orders: orders,
          ),

          const RewardsScreen(),

          CouponsView(
            coupons: controller.coupons,
            error: controller.walletError,
            onRefresh: controller.refreshWallet,
            onClaim: controller.claimCoupon,
          ),

          // Change Login page to Account page after login
          if (controller.authToken == null)
            LoginScreen(
              onLoginSuccess: () {
                setState(() {
                  currentIndex = 0;
                });
              },
            )
          else
            AccountView(
              username: controller.currentUsername,
              displayName: controller.currentDisplayName,
              role: controller.currentRole,
              onLogout: handleLogout,
            ),
        ],
      ),
      bottomNavigationBar: buildNavigationBar(controller.authToken != null),
    );
  }

  void controllerRefresh() => context.read<PaygameController>().refreshWallet();

  Widget buildNavigationBar(bool isLoggedIn) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (destinationIndex) {
        setState(() {
          currentIndex = destinationIndex;
          controllerRefresh();
        });
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'History',
        ),
        const NavigationDestination(
          icon: Icon(Icons.card_giftcard_outlined),
          selectedIcon: Icon(Icons.card_giftcard),
          label: 'Rewards',
        ),
        const NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          label: 'คูปอง',
        ),
        NavigationDestination(
          icon: Icon(isLoggedIn ? Icons.person : Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: isLoggedIn ? 'Account' : 'Login',
        ),
      ],
    );
  }
}

// Account page
class AccountView extends StatelessWidget {
  final String username;
  final String displayName;
  final String role;
  final VoidCallback onLogout;

  const AccountView({
    super.key,
    required this.username,
    required this.displayName,
    required this.role,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: const Color(0xFFA60C19),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 45),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Account Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Text('Display Name: $displayName'),
            const SizedBox(height: 8),

            Text('Username: $username'),
            const SizedBox(height: 8),

            Text('Role: ${role.toUpperCase()}'),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA60C19),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
