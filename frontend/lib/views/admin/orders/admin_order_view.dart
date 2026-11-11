import 'package:flutter/material.dart';

import 'package:frontend/services/order_service.dart';

// หน้า Orders ของ admin: แสดงรายการออเดอร์ทั้งหมดแบบสั้นๆ (ดูอย่างเดียว)
// อนุมัติ/ปฏิเสธ ทำที่แท็บ Payments ส่วนสถิติอื่นๆ อยู่ที่ Dashboard
class AdminOrdersView extends StatefulWidget {
  const AdminOrdersView({super.key});

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
  static const Color red = Color(0xFFA60C19);

  List<Map<String, dynamic>> orders = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  // ดึงออเดอร์ทั้งหมดจาก Backend (admin จะได้ของทุกคน)
  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await OrderService.list();
      if (!mounted) return;

      setState(() {
        orders = result;
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

  // สีของสถานะ
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

  // "2026-11-11T14:34:47.000Z" -> "11/11/2026 21:34"
  String formatDate(dynamic value) {
    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return '-';

    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  // ป้ายสถานะ
  Widget buildStatus(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // การ์ดออเดอร์ 1 ใบ
  Widget buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'].toString();

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFF3E7D3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // เลขออเดอร์ + สถานะ
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order['order_id']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                buildStatus(status),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '${order['game_name_snapshot']} · ${order['package_name_snapshot']}',
            ),

            const Divider(height: 24),

            Text(
              'User ID: ${order['user_id']}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Player UID: ${order['player_uid']}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${formatDate(order['created_at'])}',
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 8),

            // ยอดรวม
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '฿${order['total_amount']}',
                style: const TextStyle(
                  color: red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: red));
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
                onPressed: loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }

    return RefreshIndicator(
      onRefresh: loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: orders.map(buildOrderCard).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: buildBody(),
    );
  }
}
