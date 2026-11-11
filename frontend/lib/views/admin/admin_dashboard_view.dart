import 'package:flutter/material.dart';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/order_service.dart';

// หน้า Dashboard ของ admin: สรุปตัวเลขทั้งระบบ + ออเดอร์ล่าสุด
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  static const Color primaryColor = Color(0xFFA60C19);
  static const Color borderColor = Color(0xFFF3E7D3);

  int totalUsers = 0;
  int totalGames = 0;
  List<Map<String, dynamic>> orders = [];

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ดึงข้อมูลจาก Backend 3 ที่พร้อมกัน: users, games, orders
  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        ApiService.get('/users'), // { total_users, users }
        ApiService.get('/games/admin/all'), // { total_games, games }
        OrderService.list(), // [ orders... ] (admin เห็นทุกคน)
      ]);

      final users = results[0];
      final games = results[1];

      if (!mounted) return;

      setState(() {
        totalUsers = users is Map ? toInt(users['total_users']) : 0;
        totalGames = games is Map ? toInt(games['total_games']) : 0;
        orders = results[2] as List<Map<String, dynamic>>;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ตัวช่วยแปลงค่า (API อาจส่งมาเป็น String เช่น "35.00")
  int toInt(dynamic value) => int.tryParse(value.toString()) ?? 0;
  double toNum(dynamic value) => double.tryParse(value.toString()) ?? 0;
  String money(double value) => '฿${value.toStringAsFixed(2)}';

  // นับออเดอร์ตามสถานะ
  int countStatus(String status) {
    return orders.where((o) => o['status'] == status).length;
  }

  // รวมค่าของฟิลด์ใน "ออเดอร์ที่สำเร็จแล้ว" เท่านั้น
  double sumCompleted(String field) {
    double sum = 0;
    for (final order in orders) {
      if (order['status'] == 'Completed') {
        sum += toNum(order[field]);
      }
    }
    return sum;
  }

  // coins ที่ลูกค้าใช้ (เฉพาะออเดอร์ที่สำเร็จ)
  int get coinsUsed {
    int sum = 0;
    for (final order in orders) {
      if (order['status'] == 'Completed') {
        sum += toInt(order['spent_points']);
      }
    }
    return sum;
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // แถว "ชื่อ ... ค่า" ใช้ในกล่องสรุป
  Widget buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // กล่องสีขาวขอบครีม
  Widget buildBox({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: primaryColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ออเดอร์ล่าสุด 5 รายการ (backend เรียงใหม่สุดก่อนอยู่แล้ว)
  Widget buildRecentOrders() {
    if (orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No orders yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: orders.take(5).map((order) {
        final status = order['status'].toString();

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Order #${order['order_id']} · ${order['game_name_snapshot']}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${order['package_name_snapshot']} · ${money(toNum(order['total_amount']))}',
          ),
          trailing: Text(
            status,
            style: TextStyle(
              color: statusColor(status),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // การ์ดตัวเลข 4 ใบ
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
                children: [
                  _StatCard(
                    title: 'Total Users',
                    icon: Icons.people_outline,
                    value: '$totalUsers',
                  ),
                  _StatCard(
                    title: 'Total Games',
                    icon: Icons.sports_esports_outlined,
                    value: '$totalGames',
                  ),
                  _StatCard(
                    title: 'Total Orders',
                    icon: Icons.shopping_bag_outlined,
                    value: '${orders.length}',
                    note: '${countStatus('Pending')} pending',
                  ),
                  _StatCard(
                    title: 'Total Revenue',
                    icon: Icons.payments_outlined,
                    value: money(sumCompleted('total_amount')),
                    note: 'Completed orders only',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // สรุปออเดอร์ (ข้อมูลที่ไม่ได้โชว์ในหน้า Orders)
          buildBox(
            title: 'Order Summary',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                buildRow('Pending', '${countStatus('Pending')}'),
                buildRow('Completed', '${countStatus('Completed')}'),
                buildRow('Cancelled', '${countStatus('Cancelled')}'),
                const Divider(),
                buildRow(
                  'Coupon discount given',
                  money(sumCompleted('coupon_discount')),
                ),
                buildRow('Fees collected', money(sumCompleted('fee_amount'))),
                buildRow('Coins used', '$coinsUsed'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          buildBox(
            title: 'Recent Orders',
            icon: Icons.history,
            child: buildRecentOrders(),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (isLoading && orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(onRefresh: loadData, child: buildContent());
  }

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
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadData,
            icon: const Icon(Icons.refresh, color: primaryColor),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: buildBody(),
    );
  }
}

// การ์ดตัวเลข
class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String? note;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.value,
    this.note,
  });

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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            note ?? ' ',
            style: const TextStyle(color: goldColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
