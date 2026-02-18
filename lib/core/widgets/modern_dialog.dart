import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Optimized dialog for low-end devices
/// Uses your AppColors and AppTokens
class ModernConfirmDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String message;
  final String confirmText;
  final Color confirmColor;
  final String? warning;
  final bool isDestructive;

  const ModernConfirmDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.confirmText,
    required this.confirmColor,
    this.warning,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space3),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusLarge,
                      ),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space4),

              // Message
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),

              // Warning if provided
              if (warning != null) ...[
                const SizedBox(height: AppTokens.space4),
                Container(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppTokens.space2),
                      Expanded(
                        child: Text(
                          warning!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppTokens.space6),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppTokens.space2),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDestructive
                          ? AppColors.error
                          : confirmColor,
                      foregroundColor: isDestructive
                          ? AppColors.onError
                          : AppColors.onPrimary,
                    ),
                    child: Text(confirmText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
