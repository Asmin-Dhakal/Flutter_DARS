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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 360;
          final isVerySmall = constraints.maxWidth < 320;

          return Row(
            children: [
              Expanded(
                child: _buildCard(
                  label: 'Total',
                  value: '${orders.length}',
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                  isSmall: isSmall,
                  isVerySmall: isVerySmall,
                ),
              ),
              SizedBox(width: isSmall ? 8 : 12),
              Expanded(
                child: _buildCard(
                  label: 'Pending',
                  value:
                      '${orders.where((o) => o.status.toLowerCase() == 'notreceived').length}',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                  isSmall: isSmall,
                  isVerySmall: isVerySmall,
                ),
              ),
              SizedBox(width: isSmall ? 8 : 12),
              Expanded(
                child: _buildCard(
                  label: 'Done',
                  value:
                      '${orders.where((o) => o.status.toLowerCase() == 'completed').length}',
                  icon: Icons.done_all,
                  color: Colors.green,
                  isSmall: isSmall,
                  isVerySmall: isVerySmall,
                ),
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
    required bool isSmall,
    required bool isVerySmall,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmall ? 10 : 12,
        horizontal: isVerySmall ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isSmall ? 18 : 20),
          SizedBox(height: isSmall ? 4 : 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          SizedBox(height: isVerySmall ? 1 : 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isVerySmall ? 10 : 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
