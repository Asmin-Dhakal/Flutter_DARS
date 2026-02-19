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
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isVerySmall = size.width < 320;

    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : AppTokens.space4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray300)),
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSmall
                      ? '$selectedItemCount items'
                      : '$selectedItemCount items selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.gray600,
                    fontSize: isSmall ? 11 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmall ? 2 : AppTokens.space1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Rs. ${totalAmount.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      fontSize: isSmall ? 16 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmall ? 8 : 12),
          ElevatedButton(
            onPressed: isCreating ? null : onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : AppTokens.space6,
                vertical: isSmall ? 10 : AppTokens.space3,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: isCreating
                ? SizedBox(
                    width: isSmall ? 16 : 20,
                    height: isSmall ? 16 : 20,
                    child: SkeletonBox(
                      width: isSmall ? 16 : 20,
                      height: isSmall ? 16 : 20,
                    ),
                  )
                : Text(
                    isVerySmall ? 'Create' : 'Create Bill',
                    style: TextStyle(
                      fontSize: isSmall ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
