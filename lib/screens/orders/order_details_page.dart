import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import 'widgets/order_actions.dart';
import 'edit_order/edit_order_screen.dart';

/// Detailed view of a single order
/// Shows all order information, items, and action buttons
class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  OrderActions? _orderActions;

  @override
  void initState() {
    super.initState();
    _orderActions = OrderActions(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${widget.orderNumber}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.gray900,
        actions: [
          Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              final order = orderProvider.orders.firstWhere(
                (o) => o.id == widget.orderId,
                orElse: () => Order(
                  id: widget.orderId,
                  orderNumber: widget.orderNumber,
                  customerName: 'Unknown',
                  createdBy: 'Unknown',
                  status: 'unknown',
                  billingStatus: 'unknown',
                  orderedItems: [],
                  totalAmount: 0.0,
                  createdAt: DateTime.now(),
                  isDeleted: false,
                ),
              );

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editOrder(context, order),
                  tooltip: 'Edit Order',
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppColors.gray100,
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          // Find the specific order
          final order = orderProvider.orders.firstWhere(
            (o) => o.id == widget.orderId,
            orElse: () => Order(
              id: widget.orderId,
              orderNumber: widget.orderNumber,
              customerName: 'Unknown',
              createdBy: 'Unknown',
              status: 'notReceived',
              billingStatus: 'unbilled',
              orderedItems: [],
              totalAmount: 0,
              createdAt: DateTime.now(),
              isDeleted: false,
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header Card
                _buildOrderHeader(order),
                const SizedBox(height: 16),

                // Customer Info Section
                _buildCustomerInfo(order),
                const SizedBox(height: 16),

                // Order Items Section
                _buildOrderItems(order),
                const SizedBox(height: 16),

                // Order Summary
                _buildOrderSummary(order),
                const SizedBox(height: 16),

                // Notes Section (if any)
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  _buildNotesSection(order),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                _buildActionButtons(order),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build the order header with status and basic info
  Widget _buildOrderHeader(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Number and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.orderNumber}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Billing: ${order.billingStatus}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Created info
          Row(
            children: [
              Icon(Icons.person, size: 16, color: AppColors.gray600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Created by: ${order.createdBy}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.gray600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date info
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.gray600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Date: ${_formatDate(order.createdAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.gray600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build customer information section
  Widget _buildCustomerInfo(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      if (order.customerId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${order.customerId}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.gray600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build order items list
  Widget _buildOrderItems(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${order.orderedItems.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          ...order.orderedItems.asMap().entries.map((entry) {
            final item = entry.value;
            return Column(
              children: [
                _buildOrderItemTile(item),
                if (entry.key < order.orderedItems.length - 1)
                  Divider(color: AppColors.gray200, height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Build a single order item tile
  Widget _buildOrderItemTile(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'x${item.quantity}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NPR ${item.priceAtOrder.toStringAsFixed(2)} per item',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.gray600),
                ),
              ],
            ),
          ),

          // Item total
          Text(
            'NPR ${item.total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build order summary with total
  Widget _buildOrderSummary(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Subtotal
          _buildSummaryRow(
            'Subtotal',
            'NPR ${order.totalAmount.toStringAsFixed(2)}',
            isTotal: false,
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.gray200),
          const SizedBox(height: 12),

          // Total
          _buildSummaryRow(
            'Total',
            'NPR ${order.totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// Build a summary row
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.gray600,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isTotal ? AppColors.primary : AppColors.gray900,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Build notes section
  Widget _buildNotesSection(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_outlined, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.notes ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.gray700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(Order order) {
    final canReceive = order.status.toLowerCase() == 'notreceived';
    final canComplete =
        order.status.toLowerCase() == 'received' ||
        order.status.toLowerCase() == 'notreceived';

    return Column(
      children: [
        if (canReceive)
          _buildActionButton(
            label: 'Receive Order',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            onPressed: () => _orderActions?.receive(order.id),
          ),
        if (canReceive) const SizedBox(height: 12),
        if (canComplete)
          _buildActionButton(
            label: 'Complete Order',
            icon: Icons.done_all,
            color: AppColors.info,
            onPressed: () => _orderActions?.complete(order.id),
          ),
        if (canComplete) const SizedBox(height: 12),
        _buildActionButton(
          label: 'Cancel Order',
          icon: Icons.cancel_outlined,
          color: AppColors.error,
          onPressed: () => _orderActions?.cancel(order.id),
        ),
      ],
    );
  }

  /// Build individual action button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  /// Get status color based on order status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return AppColors.success;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      case 'notreceived':
      default:
        return AppColors.warning;
    }
  }

  /// Get readable status text
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'notreceived':
        return 'Pending';
      case 'received':
        return 'Received';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Format date
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Navigate to edit order screen
  void _editOrder(BuildContext context, Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditOrderScreen(order: order)),
    );
  }
}
