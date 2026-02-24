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
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onReceive,
    this.onComplete,
    this.onCancel,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  // Pre-computed values to avoid rebuilding
  static final Map<String, Color> _statusColors = {
    'notreceived': AppColors.warning,
    'received': AppColors.info,
    'completed': AppColors.success,
    'cancelled': AppColors.error,
  };

  static final Map<String, String> _statusLabels = {
    'notreceived': 'Pending',
    'received': 'In Progress',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  static final Map<String, Color> _billingColors = {
    'unbilled': AppColors.warning,
    'partiallybilled': AppColors.info,
    'fullybilled': AppColors.success,
  };

  Color _getStatusColor(String status) {
    return _statusColors[status.toLowerCase()] ?? AppColors.gray500;
  }

  Color _getStatusBgColor(String status) {
    final color = _getStatusColor(status);
    return color.withOpacity(0.1);
  }

  String _formatStatus(String status) {
    return _statusLabels[status.toLowerCase()] ??
        status[0].toUpperCase() + status.substring(1);
  }

  Color _getBillingColor(String billing) {
    return _billingColors[billing.toLowerCase()] ?? AppColors.gray500;
  }

  Color _getBillingBgColor(String billing) {
    final color = _getBillingColor(billing);
    return color.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          side: BorderSide(color: AppColors.outline.withOpacity(0.5)),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompactHeader(statusColor),
              const SizedBox(height: AppTokens.space2),
              _buildCompactInfo(),
              const SizedBox(height: AppTokens.space3),
              _buildCompactAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Text(
              order.orderNumber,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildStatusChip(statusColor),
      ],
    );
  }

  Widget _buildCompactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                order.customerName.isNotEmpty
                    ? order.customerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    order.customerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${order.orderedItems.length} items • Rs. ${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactAction() {
    final isCompleted = order.status.toLowerCase() == 'completed';
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final isActive = !isCompleted && !isCancelled;

    if (!isActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withOpacity(0.3)
                : AppColors.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isCompleted ? AppColors.success : AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isCompleted ? 'Completed' : 'Cancelled',
              style: TextStyle(
                color: isCompleted ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Show only primary action on card
    return ElevatedButton(
      onPressed: onReceive ?? onComplete,
      style: ElevatedButton.styleFrom(
        backgroundColor: (onReceive != null)
            ? AppColors.success
            : AppColors.info,
        foregroundColor: (onReceive != null)
            ? AppColors.onSuccess
            : AppColors.onInfo,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            onReceive != null
                ? Icons.check_circle_outline_rounded
                : Icons.done_all_rounded,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            onReceive != null ? 'Receive Order' : 'Complete Order',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
