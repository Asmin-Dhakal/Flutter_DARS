import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order.dart';
import '../../../providers/order_provider.dart';
import 'order_card.dart';
import 'order_actions.dart';

class OrderList extends StatelessWidget {
  const OrderList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    if (provider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.filteredOrders.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(context));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final order = provider.filteredOrders[index];
          return _OrderItem(order: order, actions: OrderActions(context));
        }, childCount: provider.filteredOrders.length),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final Order order;
  final OrderActions actions;

  const _OrderItem({required this.order, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(order.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => actions.delete(order.id, order.orderNumber),
      child: OrderCard(
        order: order,
        onReceive: order.status.toLowerCase() == 'notreceived'
            ? () => actions.receive(order.id)
            : null,
        onComplete: order.status.toLowerCase() == 'received'
            ? () => actions.complete(order.id)
            : null,
        onCancel:
            order.status.toLowerCase() != 'cancelled' &&
                order.status.toLowerCase() != 'completed'
            ? () => actions.cancel(order.id)
            : null,
        onEdit: () => _editOrder(context, order),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 32),
          SizedBox(height: 4),
          Text(
            'DELETE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Order?'),
            content: const Text('This will permanently delete this order.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _editOrder(BuildContext context, Order order) {
    // Navigate to edit screen
    Navigator.pushNamed(context, '/edit-order', arguments: order);
  }
}
