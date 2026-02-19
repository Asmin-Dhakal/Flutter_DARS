import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';

class OrderStats extends StatelessWidget {
  const OrderStats({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.filteredOrders;

    // Mobile-first: Use Wrap for automatic responsiveness
    // On very small screens, cards will stack vertically
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isVerySmall = constraints.maxWidth < 360;
          final cardWidth = isVerySmall ? constraints.maxWidth : null;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildCard(
                label: 'Total',
                value: '${orders.length}',
                icon: Icons.receipt_long,
                color: Colors.blue,
                width: cardWidth,
                flex: 1,
              ),
              _buildCard(
                label: 'Pending',
                value:
                    '${orders.where((o) => o.status.toLowerCase() == 'notreceived').length}',
                icon: Icons.pending_actions,
                color: Colors.orange,
                width: cardWidth,
                flex: 1,
              ),
              _buildCard(
                label: 'Done',
                value:
                    '${orders.where((o) => o.status.toLowerCase() == 'completed').length}',
                icon: Icons.done_all,
                color: Colors.green,
                width: cardWidth,
                flex: 1,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
    double? width,
    required int flex,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minWidth: 90),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
