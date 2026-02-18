import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Performance-optimized snackbar for low-end devices
/// No complex animations, simple fade
class ModernSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);

    // Clear existing to prevent queue buildup on low-end devices
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: foregroundColor ?? AppColors.onSurface,
                size: 20,
              ),
              const SizedBox(width: AppTokens.space3),
            ],
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foregroundColor ?? AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppColors.gray800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTokens.space4),
        duration: duration,
        elevation: 0,
        // Disable animation for low-end performance
        animation: null,
      ),
    );
  }

  static void success(BuildContext context, String message) => show(
    context: context,
    message: message,
    icon: Icons.check_circle_outline,
    backgroundColor: AppColors.success,
    foregroundColor: AppColors.onSuccess,
  );

  static void error(BuildContext context, String message) => show(
    context: context,
    message: message,
    icon: Icons.error_outline,
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.onError,
  );
}
