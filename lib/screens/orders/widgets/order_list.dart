import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order.dart';
import '../../../providers/order_provider.dart';
import '../../../core/widgets/skeleton.dart';
import '../edit_order/edit_order_screen.dart';
import 'order_card.dart';
import 'order_actions.dart';

class OrderList extends StatelessWidget {
  const OrderList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    if (provider.isLoading && provider.filteredOrders.isEmpty) {
      // Show skeleton placeholders matching OrderCard shape
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space4,
              vertical: AppTokens.space4,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppTokens.space3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                border: Border.all(color: AppColors.outline.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      SkeletonBox(width: 100, height: 16),
                      SizedBox(width: AppTokens.space3),
                      SkeletonBox(width: 80, height: 12),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space3),
                  Row(
                    children: const [
                      SkeletonBox(
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.all(Radius.circular(40)),
                      ),
                      SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: SkeletonBox(width: double.infinity, height: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space3),
                  const SkeletonBox(width: double.infinity, height: 12),
                  const SizedBox(height: AppTokens.space2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBox(width: 120, height: 36),
                      SkeletonBox(width: 80, height: 36),
                    ],
                  ),
                ],
              ),
            ),
          );
        }, childCount: 4),
      );
    }

    if (provider.filteredOrders.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(context));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
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
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.gray400),
          const SizedBox(height: AppTokens.space4),
          Text(
            'No orders found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Create a new order to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.gray500),
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.space4),
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
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppTokens.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
          const SizedBox(height: AppTokens.space1),
          Text(
            'DELETE',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
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
              borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
            ),
            title: const Text('Delete Order?'),
            content: const Text(
              'This will permanently delete this order. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _editOrder(BuildContext context, Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditOrderScreen(order: order)),
    );
  }
}
