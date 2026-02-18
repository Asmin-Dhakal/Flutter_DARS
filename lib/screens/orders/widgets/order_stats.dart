import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';

class OrderStats extends StatelessWidget {
  const OrderStats({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.filteredOrders;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildCard(
            label: 'Total',
            value: '${orders.length}',
            icon: Icons.receipt_long,
            color: Colors.blue,
          ),
          const SizedBox(width: 16),
          _buildCard(
            label: 'Pending',
            value:
                '${orders.where((o) => o.status.toLowerCase() == 'notreceived').length}',
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
          _buildCard(
            label: 'Completed',
            value:
                '${orders.where((o) => o.status.toLowerCase() == 'completed').length}',
            icon: Icons.done_all,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
