import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bill.dart';

/// Lightweight, modular header for the Create Bill flow
/// Optimized for all screen sizes
class CreateBillHeader extends StatelessWidget {
  final UnbilledCustomer initialCustomer;
  final VoidCallback onAddOtherCustomer;
  final VoidCallback onBack;

  const CreateBillHeader({
    super.key,
    required this.initialCustomer,
    required this.onAddOtherCustomer,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isVerySmall = size.width < 320;

    return Padding(
      padding: EdgeInsets.all(isSmall ? 12 : AppTokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Title and Back button
          Row(
            children: [
              Expanded(
                child: Text(
                  isSmall ? 'Select Items' : 'Create Bill - Select Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    fontSize: isSmall ? 16 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(
                  isVerySmall ? '' : 'Back',
                ), // Hide text on very small
                style: TextButton.styleFrom(foregroundColor: AppColors.gray700),
              ),
            ],
          ),

          SizedBox(height: isSmall ? 8 : AppTokens.space2),

          // Customer info row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bill for: ${initialCustomer.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: isSmall ? 13 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: isSmall ? 8 : AppTokens.space2),
              OutlinedButton.icon(
                onPressed: onAddOtherCustomer,
                icon: const Icon(Icons.add, size: 16),
                label: Text(isSmall ? 'Add' : 'Add Others'), // Shorter text
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 10 : AppTokens.space3,
                    vertical: isSmall ? 6 : AppTokens.space2,
                  ),
                  textStyle: TextStyle(fontSize: isSmall ? 11 : 12),
                  minimumSize: Size.zero, // Allow smaller size
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
