import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Modern Status Filter Widget
/// Follows Material 3 design with semantic colors and optimized for low-end devices
class StatusFilter extends StatelessWidget {
  final String selectedStatus;
  final List<String> statusOptions;
  final Function(String) onStatusChanged;

  const StatusFilter({
    super.key,
    required this.selectedStatus,
    required this.statusOptions,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : AppTokens.space3,
        vertical: isSmall ? 8 : AppTokens.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: AppColors.gray600),
          items: statusOptions.map((status) {
            return DropdownMenuItem(
              value: status,
              child: _buildDropdownItem(status),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onStatusChanged(value);
            }
          },
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray800,
          ),
        ),
      ),
    );
  }

  /// Builds dropdown item with icon and formatted text
  Widget _buildDropdownItem(String status) {
    final icon = _getStatusIcon(status);
    final color = _getStatusColor(status);
    final label = _formatStatus(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppTokens.space2),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  /// Get semantic color for status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'partially_paid':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.gray600;
    }
  }

  /// Get icon for each status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'all':
        return Icons.list_outlined;
      case 'pending':
        return Icons.schedule_outlined;
      case 'paid':
        return Icons.check_circle_outlined;
      case 'partially_paid':
        return Icons.remove_circle_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// Format status for display
  String _formatStatus(String status) {
    switch (status) {
      case 'all':
        return 'All Status';
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'partially_paid':
        return 'Partially Paid';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
