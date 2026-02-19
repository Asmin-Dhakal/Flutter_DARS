import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Optimized dialog for all screen sizes
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
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isVerySmall = size.width < 320;

    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 16 : 24,
        vertical: isSmall ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          isSmall ? 16 : AppTokens.radiusXLarge,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          minWidth: isVerySmall ? 280 : 320,
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 16 : AppTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmall ? 8 : AppTokens.space3),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        isSmall ? 10 : AppTokens.radiusLarge,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: isSmall ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmall ? 10 : AppTokens.space3),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: isSmall ? 18 : null,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmall ? 12 : AppTokens.space4),

              // Message
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: isSmall ? 14 : null,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Warning if provided
              if (warning != null) ...[
                SizedBox(height: isSmall ? 12 : AppTokens.space4),
                Container(
                  padding: EdgeInsets.all(isSmall ? 10 : AppTokens.space3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(
                      isSmall ? 8 : AppTokens.radiusMedium,
                    ),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: isSmall ? 18 : 20,
                      ),
                      SizedBox(width: isSmall ? 8 : AppTokens.space2),
                      Expanded(
                        child: Text(
                          warning!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.error,
                                fontSize: isSmall ? 12 : null,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: isSmall ? 16 : AppTokens.space6),

              // Actions - Stack vertically on very small screens
              isVerySmall
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: isDestructive
                                  ? AppColors.error
                                  : confirmColor,
                              foregroundColor: isDestructive
                                  ? AppColors.onError
                                  : AppColors.onPrimary,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmall ? 12 : 16,
                              ),
                            ),
                            child: Text(
                              confirmText,
                              style: TextStyle(
                                fontSize: isSmall ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmall ? 8 : 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isSmall ? 12 : 16,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(fontSize: isSmall ? 13 : 14),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 12 : 16,
                              vertical: isSmall ? 8 : 12,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: isSmall ? 13 : 14),
                          ),
                        ),
                        SizedBox(width: isSmall ? 8 : AppTokens.space2),
                        Flexible(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: isDestructive
                                  ? AppColors.error
                                  : confirmColor,
                              foregroundColor: isDestructive
                                  ? AppColors.onError
                                  : AppColors.onPrimary,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmall ? 16 : 24,
                                vertical: isSmall ? 10 : 16,
                              ),
                            ),
                            child: Text(
                              confirmText,
                              style: TextStyle(
                                fontSize: isSmall ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
