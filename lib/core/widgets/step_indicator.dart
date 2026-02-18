import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Material 3 step indicator optimized for low-end devices
class StepIndicator extends StatelessWidget {
  final List<StepItem> steps;
  final int currentStep;

  const StepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: _StepNode(
                  label: step.label,
                  icon: step.icon,
                  isActive: isActive,
                  isCurrent: isCurrent,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space2,
                    ),
                    decoration: BoxDecoration(
                      color: index < currentStep
                          ? AppColors.success
                          : AppColors.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class StepItem {
  final String label;
  final IconData icon;

  const StepItem({required this.label, required this.icon});
}

class _StepNode extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isCurrent;

  const _StepNode({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppColors.success : AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.success : AppColors.outline,
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isActive ? Icons.check : icon,
            size: 18,
            color: isActive ? AppColors.onSuccess : AppColors.gray500,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.success : AppColors.gray600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
