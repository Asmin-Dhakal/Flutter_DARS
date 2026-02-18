import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modern bottom action bar with glassmorphism effect
class ModernBottomBar extends StatelessWidget {
  final Widget child;
  final double height;

  const ModernBottomBar({super.key, required this.child, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: AppColors.outline.withOpacity(0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        minimum: const EdgeInsets.all(AppTokens.space4),
        child: child,
      ),
    );
  }
}
