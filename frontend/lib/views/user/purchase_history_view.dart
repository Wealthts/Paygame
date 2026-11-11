import 'package:flutter/material.dart';

import 'game_detail_view.dart';
import 'package:frontend/services/order_service.dart';

class PurchaseHistoryView extends StatefulWidget {
  const PurchaseHistoryView({super.key, required this.orders});

  final List<PaygameOrder> orders;

  @override
  State<PurchaseHistoryView> createState() => _PurchaseHistoryViewState();
}

class _PurchaseHistoryViewState extends State<PurchaseHistoryView> {
  Future<List<Map<String, dynamic>>>? _orders;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _orders = OrderService.list());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการซื้อ'), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return const Center(child: Text('ยังไม่มีรายการซื้อ'));
          return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      '${order['game_name_snapshot']} · ${order['package_name_snapshot']}',
                    ),
                    subtitle: Text(
                      'คำสั่งซื้อ GP-${order['order_id']}\n'
                      'ชำระ ฿${order['total_amount']} · สถานะ ${order['status']}',
                    ),
                    isThreeLine: true,
                    trailing: Text('${order['status']}'),
                  ),
                );
              },
            );
        },
      ),
    );
  }
}
