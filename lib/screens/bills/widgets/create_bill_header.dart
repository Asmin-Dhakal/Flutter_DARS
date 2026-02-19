import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/bill.dart';

/// Lightweight, modular header for the Create Bill flow
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
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Bill - Select Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Row(
                  children: [
                    Text(
                      'Bill for: ${initialCustomer.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space2),
                    OutlinedButton.icon(
                      onPressed: onAddOtherCustomer,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Others'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.space3,
                          vertical: AppTokens.space2,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gray700),
          ),
        ],
      ),
    );
  }
}
