import 'package:flutter/material.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  static const Color primaryColor = Color(0xFFA60C19);
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color borderColor = Color(0xFFF3E7D3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page heading
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292929),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage and monitor your GamePay system.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 28),

            // Statistics
            LayoutBuilder(
              builder: (context, constraints) {
                int columns = 1;

                if (constraints.maxWidth >= 900) {
                  columns = 4;
                } else if (constraints.maxWidth >= 550) {
                  columns = 2;
                }

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: columns == 1 ? 3.0 : 1.5,
                  children: const [
                    _StatCard(title: 'Total Users', icon: Icons.people_outline),
                    _StatCard(
                      title: 'Total Games',
                      icon: Icons.sports_esports_outlined,
                    ),
                    _StatCard(
                      title: 'Total Orders',
                      icon: Icons.shopping_bag_outlined,
                    ),
                    _StatCard(
                      title: 'Total Revenue',
                      icon: Icons.payments_outlined,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Recent activity
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: primaryColor),
                      SizedBox(width: 10),
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No activity data available',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Connect the backend API to display data.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Statistics card
class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _StatCard({required this.title, required this.icon});

  static const Color primaryColor = Color(0xFFA60C19);
  static const Color goldColor = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              Icon(icon, color: primaryColor, size: 24),
            ],
          ),
          const Text(
            '--',
            style: TextStyle(
              color: primaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Waiting for API',
            style: TextStyle(color: goldColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
