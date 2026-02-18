import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OrderSummaryCard extends StatelessWidget {
  final int itemCount;
  final double totalAmount;
  final VoidCallback? onTap;

  const OrderSummaryCard({
    super.key,
    required this.itemCount,
    required this.totalAmount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space4),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.space3),
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              ),
              child: Badge(
                isLabelVisible: itemCount > 0,
                label: Text('$itemCount'),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.onPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      color: AppColors.onPrimary.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.onPrimary.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
