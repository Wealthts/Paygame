import 'package:flutter/material.dart';

import 'package:frontend/views/admin/admin_dashboard_view.dart';
import 'package:frontend/views/admin/games/admin_game_view.dart';
import 'package:frontend/views/admin/orders/admin_order_view.dart';
import 'package:frontend/views/admin/packages/admin_package_view.dart';
import 'package:frontend/views/admin/payments/admin_payment_view.dart';
import 'package:frontend/views/admin/points/admin_point_view.dart';
import 'package:frontend/views/admin/receipts/admin_receipt_view.dart';
import 'package:frontend/views/admin/users/admin_user_view.dart';

class AdminShellView extends StatefulWidget {
  const AdminShellView({super.key});

  @override
  State<AdminShellView> createState() => _AdminShellViewState();
}

class _AdminShellViewState extends State<AdminShellView> {
  // Selected page
  int currentIndex = 0;

  // Main color
  static const Color primaryColor = Color(0xFFA60C19);
  static const Color goldColor = Color(0xFFD4AF37);

  // Admin pages
  final List<Widget> pages = const [
    AdminDashboardView(),
    AdminGamesView(),
    AdminPackagesView(),
    AdminOrdersView(),
    AdminPaymentsView(),
    AdminPointsView(),
    AdminReceiptsView(),
    AdminUsersView(),
  ];

  // Navigation menu
  final List<NavigationDestination> destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.sports_esports_outlined),
      selectedIcon: Icon(Icons.sports_esports),
      label: 'Games',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Packages',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Orders',
    ),
    NavigationDestination(
      icon: Icon(Icons.payment_outlined),
      selectedIcon: Icon(Icons.payment),
      label: 'Payments',
    ),
    NavigationDestination(
      icon: Icon(Icons.stars_outlined),
      selectedIcon: Icon(Icons.stars),
      label: 'Points',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_outlined),
      selectedIcon: Icon(Icons.receipt),
      label: 'Receipts',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Users',
    ),
  ];

  // Change page
  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                // Side navigation
                Container(
                  color: Colors.white,
                  child: NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: changePage,
                    extended: constraints.maxWidth >= 1200,
                    backgroundColor: Colors.white,
                    indicatorColor: primaryColor.withOpacity(0.10),
                    selectedIconTheme: const IconThemeData(color: primaryColor),
                    unselectedIconTheme: const IconThemeData(
                      color: Colors.grey,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.sports_esports,
                            color: primaryColor,
                            size: 36,
                          ),
                          if (constraints.maxWidth >= 1200) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'GAMEPAY',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    destinations: destinations.map((item) {
                      return NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: Text(item.label),
                      );
                    }).toList(),
                  ),
                ),

                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFF3E7D3),
                ),

                // Main content
                Expanded(
                  child: IndexedStack(index: currentIndex, children: pages),
                ),
              ],
            ),
          );
        }

        // Mobile and tablet layout
        return Scaffold(
          body: IndexedStack(index: currentIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: changePage,
            indicatorColor: primaryColor.withOpacity(0.10),
            destinations: destinations,
          ),
        );
      },
    );
  }
}
