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
    final billingColor = _getBillingColor(order.billingStatus);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero, // Control margin from parent
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        side: BorderSide(color: AppColors.outline.withOpacity(0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 350;
          final isVerySmall = constraints.maxWidth < 300;

          return Column(
            mainAxisSize: MainAxisSize.min, // Critical for performance
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(statusColor, isSmall),
              if (order.billingStatus.toLowerCase() != 'fullybilled')
                _buildBillingStatus(billingColor),
              if (order.notes != null && order.notes!.isNotEmpty)
                _buildNotes(isSmall),
              if (order.orderedItems.isNotEmpty) _buildItems(isSmall),
              _buildActions(isSmall, isVerySmall),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Color statusColor, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : AppTokens.space4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLarge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order Number and Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(statusColor),
            ],
          ),
          SizedBox(height: isSmall ? 10 : AppTokens.space3),

          // Customer Info - Optimized for small screens
          Row(
            children: [
              CircleAvatar(
                radius: isSmall ? 16 : 20,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  order.customerName.isNotEmpty
                      ? order.customerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 12 : 14,
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 10 : AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.customerName,
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${order.createdBy}',
                      style: TextStyle(
                        fontSize: isSmall ? 10 : 12,
                        color: AppColors.gray600,
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

  Widget _buildBillingStatus(Color billingColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getBillingBgColor(order.billingStatus),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_outlined, size: 14, color: billingColor),
          const SizedBox(width: 6),
          Text(
            order.billingStatus[0].toUpperCase() +
                order.billingStatus.substring(1),
            style: TextStyle(
              fontSize: 11,
              color: billingColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(bool isSmall) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : AppTokens.space4,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes_rounded, size: 14, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              order.notes!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.info,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItems(bool isSmall) {
    return Container(
      margin: EdgeInsets.all(isSmall ? 12 : AppTokens.space4),
      padding: EdgeInsets.all(isSmall ? 12 : AppTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Use ListView.builder for better performance with many items
          ..._buildItemRows(isSmall),
          const Divider(height: 20, thickness: 1),
          _buildTotalRow(isSmall),
        ],
      ),
    );
  }

  List<Widget> _buildItemRows(bool isSmall) {
    final List<Widget> rows = [];

    for (int i = 0; i < order.orderedItems.length; i++) {
      final item = order.orderedItems[i];
      final isLast = i == order.orderedItems.length - 1;

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: Text(
                  '${item.quantity}x',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontSize: isSmall ? 12 : 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rs. ${item.total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isSmall ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

      if (!isLast) {
        rows.add(
          Divider(height: 12, color: AppColors.outline.withOpacity(0.2)),
        );
      }
    }

    return rows;
  }

  Widget _buildTotalRow(bool isSmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total',
          style: TextStyle(
            fontSize: isSmall ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Rs. ${order.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isSmall, bool isVerySmall) {
    final isCompleted = order.status.toLowerCase() == 'completed';
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final isActive = !isCompleted && !isCancelled;

    if (!isActive) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.all(isSmall ? 12 : AppTokens.space4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isCompleted ? AppColors.success : AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isCompleted ? 'Order Completed' : 'Order Cancelled',
                style: TextStyle(
                  color: isCompleted ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Adaptive action layout
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : AppTokens.space4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.outline.withOpacity(0.3)),
        ),
      ),
      child: isVerySmall
          ? _buildCompactActions() // Stack vertically on very small screens
          : _buildRowActions(isSmall), // Row layout for normal screens
    );
  }

  Widget _buildRowActions(bool isSmall) {
    return Row(
      children: [
        // Primary Action
        if (onReceive != null)
          Expanded(
            flex: 2,
            child: _ActionButton(
              onPressed: onReceive,
              icon: Icons.check_circle_outline_rounded,
              label: isSmall ? 'Receive' : 'Receive',
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.onSuccess,
              isCompact: isSmall,
            ),
          )
        else if (onComplete != null)
          Expanded(
            flex: 2,
            child: _ActionButton(
              onPressed: onComplete,
              icon: Icons.done_all_rounded,
              label: isSmall ? 'Complete' : 'Complete',
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.onInfo,
              isCompact: isSmall,
            ),
          ),

        SizedBox(width: isSmall ? 8 : 12),

        // Secondary Actions
        Expanded(
          child: Row(
            children: [
              if (onCancel != null)
                Expanded(
                  child: _IconActionButton(
                    onPressed: onCancel,
                    icon: Icons.cancel_outlined,
                    tooltip: 'Cancel',
                    color: AppColors.error,
                    isCompact: isSmall,
                  ),
                ),
              if (onCancel != null && onEdit != null)
                SizedBox(width: isSmall ? 6 : 8),
              if (onEdit != null)
                Expanded(
                  child: _IconActionButton(
                    onPressed: onEdit,
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    color: AppColors.gray700,
                    isCompact: isSmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActions() {
    // Vertical stack for very small screens (< 300px)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onReceive != null)
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              onPressed: onReceive,
              icon: Icons.check_circle_outline_rounded,
              label: 'Receive',
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.onSuccess,
              isCompact: true,
            ),
          )
        else if (onComplete != null)
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              onPressed: onComplete,
              icon: Icons.done_all_rounded,
              label: 'Complete',
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.onInfo,
              isCompact: true,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (onCancel != null)
              Expanded(
                child: _IconActionButton(
                  onPressed: onCancel,
                  icon: Icons.cancel_outlined,
                  tooltip: 'Cancel',
                  color: AppColors.error,
                  isCompact: true,
                ),
              ),
            if (onCancel != null && onEdit != null) const SizedBox(width: 8),
            if (onEdit != null)
              Expanded(
                child: _IconActionButton(
                  onPressed: onEdit,
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit',
                  color: AppColors.gray700,
                  isCompact: true,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Optimized action button with compact mode
class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isCompact;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 10 : 12,
        ),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 16 : 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized icon button with compact mode
class _IconActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool isCompact;

  const _IconActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.color,
    this.isCompact = false,
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
            height: isCompact ? 40 : 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Center(
              child: Icon(icon, color: color, size: isCompact ? 18 : 20),
            ),
          ),
        ),
      ),
    );
  }
}
