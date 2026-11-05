import 'package:flutter/material.dart';

import 'game_detail_view.dart';
import 'receipt_view.dart';

class PurchaseHistoryView extends StatelessWidget {
  const PurchaseHistoryView({super.key, required this.orders});

  final List<PaygameOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการซื้อ')),
      body: orders.isEmpty
          ? const Center(child: Text('ยังไม่มีรายการซื้อ'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final date = order.createdAt;
                return Card(
                  child: ListTile(
                    title: Text(
                      '${order.game.name} · ${order.pack.quantity} ${order.game.unit}',
                    ),
                    subtitle: Text(
                      '${date.day}/${date.month}/${date.year + 543} · ${order.id}\n'
                      'ชำระ ฿${(order.totalSatang / 100).toStringAsFixed(2)} · ได้รับ ${order.earnedPoints} แต้ม',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ReceiptScreen(order: order),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
