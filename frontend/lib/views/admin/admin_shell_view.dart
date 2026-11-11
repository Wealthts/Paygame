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
  final Future<void> Function()? onLogout;

  const AdminShellView({super.key, this.onLogout});

  @override
  State<AdminShellView> createState() => _AdminShellViewState();
}

class _AdminShellViewState extends State<AdminShellView> {
  int currentIndex = 0;
  bool isLoggingOut = false;

  static const Color primaryColor = Color(0xFFA60C19);

  final List<Widget> pages = const [
    AdminDashboardView(),
    AdminTabGroupView(
      tabs: [
        Tab(icon: Icon(Icons.sports_esports_outlined), text: 'Games'),
        Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Packages'),
      ],
      children: [
        AdminGamesView(),
        AdminPackagesView(),
      ],
    ),
    AdminTabGroupView(
      tabs: [
        Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders'),
        Tab(icon: Icon(Icons.payment_outlined), text: 'Payments'),
        Tab(icon: Icon(Icons.receipt_outlined), text: 'Receipts'),
        Tab(icon: Icon(Icons.stars_outlined), text: 'Points'),
      ],
      children: [
        AdminOrdersView(),
        AdminPaymentsView(),
        AdminReceiptsView(),
        AdminPointsView(),
      ],
    ),
    AdminUsersView(),
  ];

  final List<NavigationDestination> destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category),
      label: 'Catalog',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Orders',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Users',
    ),
  ];

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> handleLogout() async {
    if (widget.onLogout == null || isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      await widget.onLogout!();
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        isLoggingOut = false;
      });
    }
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
                Container(
                  color: Colors.white,
                  child: NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: changePage,
                    extended: constraints.maxWidth >= 1200,
                    backgroundColor: Colors.white,
                    indicatorColor: primaryColor.withValues(alpha: 0.10),
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
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: IconButton(
                            tooltip: 'Logout',
                            icon: const Icon(Icons.logout, color: primaryColor),
                            onPressed: isLoggingOut ? null : handleLogout,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFF3E7D3),
                ),

                Expanded(
                  child: IndexedStack(index: currentIndex, children: pages),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(index: currentIndex, children: pages),
          floatingActionButton: FloatingActionButton(
            onPressed: isLoggingOut ? null : handleLogout,
            backgroundColor: primaryColor,
            tooltip: 'Logout',
            child: const Icon(Icons.logout, color: Colors.white),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: changePage,
            indicatorColor: primaryColor.withValues(alpha: 0.10),
            destinations: destinations,
          ),
        );
      },
    );
  }
}

/// Groups several admin pages under one menu item, switched with a tab bar.
class AdminTabGroupView extends StatelessWidget {
  final List<Tab> tabs;
  final List<Widget> children;

  const AdminTabGroupView({
    super.key,
    required this.tabs,
    required this.children,
  });

  static const Color primaryColor = Color(0xFFA60C19);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              tabs: tabs,
              isScrollable: tabs.length > 3,
              tabAlignment: tabs.length > 3 ? TabAlignment.start : null,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
