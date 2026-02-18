import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onReceive;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OrderCard({
    super.key,
    required this.order,
    this.onReceive,
    this.onComplete,
    this.onCancel,
    this.onEdit,
    this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'notreceived':
        return AppColors.warning;
      case 'received':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'notreceived':
        return AppColors.warning.withOpacity(0.1);
      case 'received':
        return AppColors.info.withOpacity(0.1);
      case 'completed':
        return AppColors.success.withOpacity(0.1);
      case 'cancelled':
        return AppColors.error.withOpacity(0.1);
      default:
        return AppColors.gray200;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'notreceived':
        return 'Pending';
      case 'received':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _getBillingColor(String billing) {
    switch (billing.toLowerCase()) {
      case 'unbilled':
        return AppColors.warning;
      case 'partiallybilled':
        return AppColors.info;
      case 'fullybilled':
        return AppColors.success;
      default:
        return AppColors.gray500;
    }
  }

  Color _getBillingBgColor(String billing) {
    switch (billing.toLowerCase()) {
      case 'unbilled':
        return AppColors.warning.withOpacity(0.1);
      case 'partiallybilled':
        return AppColors.info.withOpacity(0.1);
      case 'fullybilled':
        return AppColors.success.withOpacity(0.1);
      default:
        return AppColors.gray200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final billingColor = _getBillingColor(order.billingStatus);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        side: BorderSide(color: AppColors.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(statusColor),

          // Billing Status
          if (order.billingStatus.toLowerCase() != 'fullybilled')
            _buildBillingStatus(billingColor),

          // Notes
          if (order.notes != null && order.notes!.isNotEmpty) _buildNotes(),

          // Items
          if (order.orderedItems.isNotEmpty) _buildItems(),

          // Actions - REDESIGNED
          _buildModernActions(),
        ],
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLarge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Number and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildStatusChip(statusColor),
            ],
          ),
          const SizedBox(height: AppTokens.space3),

          // Customer Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  order.customerName[0].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Created by ${order.createdBy}',
                      style: TextStyle(fontSize: 12, color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space3,
        vertical: AppTokens.space1,
      ),
      decoration: BoxDecoration(
        color: _getStatusBgColor(order.status),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
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
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingStatus(Color billingColor) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space2,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space3,
        vertical: AppTokens.space2,
      ),
      decoration: BoxDecoration(
        color: _getBillingBgColor(order.billingStatus),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_outlined, size: 16, color: billingColor),
          const SizedBox(width: AppTokens.space2),
          Text(
            order.billingStatus[0].toUpperCase() +
                order.billingStatus.substring(1),
            style: TextStyle(
              fontSize: 12,
              color: billingColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space2,
      ),
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.notes_rounded, size: 16, color: AppColors.info),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              order.notes!,
              style: TextStyle(fontSize: 13, color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItems() {
    return Container(
      margin: const EdgeInsets.all(AppTokens.space4),
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space2,
                        vertical: AppTokens.space1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusSmall,
                        ),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
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
                  Divider(
                    height: AppTokens.space4,
                    color: AppColors.outline.withOpacity(0.3),
                  ),
              ],
            );
          }),
          const Divider(height: AppTokens.space5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NEW: Modern action layout
  Widget _buildModernActions() {
    final isCompleted = order.status.toLowerCase() == 'completed';
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final isActive = !isCompleted && !isCancelled;

    if (!isActive) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(AppTokens.space4),
        padding: const EdgeInsets.all(AppTokens.space3),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isCompleted ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: AppTokens.space2),
            Text(
              isCompleted ? 'Order Completed' : 'Order Cancelled',
              style: TextStyle(
                color: isCompleted ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.outline.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // Primary Action (Receive/Complete) - Takes most space
          if (onReceive != null)
            Expanded(
              flex: 3,
              child: _ActionButton(
                onPressed: onReceive,
                icon: Icons.check_circle_outline_rounded,
                label: 'Receive',
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.onSuccess,
              ),
            )
          else if (onComplete != null)
            Expanded(
              flex: 3,
              child: _ActionButton(
                onPressed: onComplete,
                icon: Icons.done_all_rounded,
                label: 'Complete',
                backgroundColor: AppColors.info,
                foregroundColor: AppColors.onInfo,
              ),
            ),

          const SizedBox(width: AppTokens.space3),

          // Secondary Actions in a row
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // Cancel Button (Icon only with tooltip for space)
                if (onCancel != null)
                  Expanded(
                    child: _IconActionButton(
                      onPressed: onCancel,
                      icon: Icons.cancel_outlined,
                      tooltip: 'Cancel Order',
                      color: AppColors.error,
                    ),
                  ),

                if (onCancel != null && onEdit != null)
                  const SizedBox(width: AppTokens.space2),

                // Edit Button
                if (onEdit != null)
                  Expanded(
                    child: _IconActionButton(
                      onPressed: onEdit,
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit Order',
                      color: AppColors.gray700,
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

// NEW: Custom action button widget
class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppTokens.space2),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// NEW: Icon-only action button with tooltip
class _IconActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;

  const _IconActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Center(child: Icon(icon, color: color, size: 20)),
          ),
        ),
      ),
    );
  }
}
