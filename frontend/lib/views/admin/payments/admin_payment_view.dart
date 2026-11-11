import 'package:flutter/material.dart';
import 'package:frontend/services/payment_service.dart';

class AdminPaymentsView extends StatefulWidget {
  const AdminPaymentsView({super.key});

  @override
  State<AdminPaymentsView> createState() => _AdminPaymentsViewState();
}

class _AdminPaymentsViewState extends State<AdminPaymentsView> {
  Future<List<Map<String, dynamic>>>? _payments;
  int? _updatingId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _payments = PaymentService.listForAdmin());

  Future<void> _update(int paymentId, String status) async {
    setState(() => _updatingId = paymentId);
    try {
      await PaymentService.updateStatus(paymentId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'Paid' ? 'Approved' : 'Rejected')));
      _reload();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Payment Management'), actions: [IconButton(onPressed: _updatingId == null ? _reload : null, icon: const Icon(Icons.refresh))]),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _payments,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
            final payments = snapshot.data ?? [];
            if (payments.isEmpty) return const Center(child: Text('No payments found'));
            return ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                final id = int.tryParse(payment['payment_id'].toString()) ?? 0;
                final pending = payment['status'] == 'Pending';
                return Card(child: ListTile(
                  title: Text('${payment['game_name_snapshot']} · ${payment['package_name_snapshot']}'),
                  subtitle: Text('${payment['display_name'] ?? payment['username']} · ฿${payment['amount']}\n${payment['method']} · ${payment['transaction_ref']}'),
                  isThreeLine: true,
                  trailing: pending ? Wrap(spacing: 4, children: [
                    IconButton(onPressed: _updatingId == null ? () => _update(id, 'Paid') : null, icon: const Icon(Icons.check_circle, color: Colors.green)),
                    IconButton(onPressed: _updatingId == null ? () => _update(id, 'Failed') : null, icon: const Icon(Icons.cancel, color: Colors.red)),
                  ]) : Text('${payment['status']}'),
                ));
              },
            );
          },
        ),
      );
}
