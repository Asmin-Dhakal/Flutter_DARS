import 'package:flutter/material.dart';
import '../../../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onReceive;
  final VoidCallback? onComplete; // Add this
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OrderCard({
    super.key,
    required this.order,
    this.onReceive,
    this.onComplete, // Add this
    this.onCancel,
    this.onEdit,
    this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'notreceived':
        return Colors.orange;
      case 'received':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'notreceived':
        return Colors.orange.shade50;
      case 'received':
        return Colors.green.shade50;
      case 'cancelled':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'notreceived':
        return 'Not Received';
      case 'partiallybilled':
        return 'Partially Billed';
      case 'fullybilled':
        return 'Fully Billed';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _getBillingColor(String billing) {
    switch (billing.toLowerCase()) {
      case 'unbilled':
        return Colors.orange;
      case 'partiallybilled':
        return Colors.blue;
      case 'fullybilled':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getBillingBgColor(String billing) {
    switch (billing.toLowerCase()) {
      case 'unbilled':
        return Colors.orange.shade50;
      case 'partiallybilled':
        return Colors.blue.shade50;
      case 'fullybilled':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final billingColor = _getBillingColor(order.billingStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.white],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Number and Badges Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.orderNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(order.status),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatStatus(order.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Customer Name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        order.customerName[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Created by ${order.createdBy}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey.shade200),

          // Billing Status Badge (if not fully billed)
          if (order.billingStatus.toLowerCase() != 'fullybilled')
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getBillingBgColor(order.billingStatus),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: billingColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_outlined, size: 16, color: billingColor),
                  const SizedBox(width: 8),
                  Text(
                    _formatStatus(order.billingStatus),
                    style: TextStyle(
                      fontSize: 12,
                      color: billingColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Notes (if any)
          if (order.notes != null && order.notes!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Items List
          if (order.orderedItems.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ...order.orderedItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isLast = index == order.orderedItems.length - 1;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${item.quantity}x',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              'Rs. ${item.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (!isLast)
                          Divider(height: 16, color: Colors.grey.shade300),
                      ],
                    );
                  }),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          if (order.orderedItems.isNotEmpty &&
              order.status.toLowerCase() != 'cancelled' &&
              order.status.toLowerCase() != 'completed') ...[
            Row(
              children: [
                // Receive Button (only if not received)
                if (order.status.toLowerCase() == 'notreceived') ...[
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onReceive,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Receive'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Complete Button (only if received)
                if (order.status.toLowerCase() == 'received') ...[
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Cancel Button (only if not completed)
                if (order.status.toLowerCase() != 'completed') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Edit Button
                IconButton(
                  onPressed: onEdit,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (order.status.toLowerCase() == 'completed')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Order Completed',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
