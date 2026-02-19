import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';

class BillSummary extends StatelessWidget {
  final int selectedItemCount;
  final double totalAmount;
  final bool isCreating;
  final VoidCallback onCreate;

  const BillSummary({
    super.key,
    required this.selectedItemCount,
    required this.totalAmount,
    required this.isCreating,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray300)),
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$selectedItemCount items selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: AppTokens.space1),
              Text(
                'Total: Rs. ${totalAmount.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: isCreating ? null : onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space6,
                vertical: AppTokens.space3,
              ),
            ),
            child: isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: SkeletonBox(width: 20, height: 20),
                  )
                : const Text('Create Bill'),
          ),
        ],
      ),
    );
  }
}
