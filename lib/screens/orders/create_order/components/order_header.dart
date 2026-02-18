import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OrderHeader extends StatelessWidget {
  final String orderNumber;
  final DateTime createdAt;
  final String status;

  const OrderHeader({
    super.key,
    required this.orderNumber,
    required this.createdAt,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: AppColors.onPrimary.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: AppTokens.space2),
              Text(
                'ORDER',
                style: TextStyle(
                  color: AppColors.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            orderNumber,
            style: const TextStyle(
              color: AppColors.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space3,
              vertical: AppTokens.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Text(
              _formatDate(createdAt),
              style: TextStyle(
                color: AppColors.onPrimary.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
