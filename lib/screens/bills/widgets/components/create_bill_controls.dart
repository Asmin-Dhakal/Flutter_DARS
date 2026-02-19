import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CreateBillControls extends StatelessWidget {
  final int selectedItemCount;
  final bool isAllSelected;
  final VoidCallback onToggleSelectAll;
  final TextEditingController notesController;

  const CreateBillControls({
    super.key,
    required this.selectedItemCount,
    required this.isAllSelected,
    required this.onToggleSelectAll,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Items to Bill',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: onToggleSelectAll,
              child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space4),
        Text(
          'Notes (optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any notes for this bill...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            ),
            contentPadding: const EdgeInsets.all(AppTokens.space3),
          ),
        ),
      ],
    );
  }
}
