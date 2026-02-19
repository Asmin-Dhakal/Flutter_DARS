import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/menu_item.dart' as models;

class MenuGrid extends StatelessWidget {
  final List<models.MenuItem> items;
  final Map<String, int> cart;
  final Function(models.MenuItem) onAdd;
  final Function(models.MenuItem)? onRemove;

  const MenuGrid({
    super.key,
    required this.items,
    required this.cart,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: AppTokens.space3,
        mainAxisSpacing: AppTokens.space3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final quantity = cart[item.id] ?? 0;

        return _MenuItemTile(
          item: item,
          quantity: quantity,
          onAdd: () => onAdd(item),
          onRemove: quantity > 0 ? () => onRemove?.call(item) : null,
        );
      },
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final models.MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const _MenuItemTile({
    required this.item,
    required this.quantity,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuantity = quantity > 0;

    return Material(
      color: hasQuantity
          ? AppColors.primaryContainer
          : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(
              color: hasQuantity
                  ? AppColors.primary.withOpacity(0.5)
                  : AppColors.outline.withOpacity(0.3),
              width: hasQuantity ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppTokens.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasQuantity) ...[
                    const SizedBox(width: AppTokens.space2),
                    _QuantityBadge(quantity: quantity),
                  ],
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs. ${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (hasQuantity)
                        Text(
                          'Rs. ${(item.price * quantity).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.gray600,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  if (hasQuantity && onRemove != null)
                    _RemoveButton(onTap: onRemove!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  final int quantity;

  const _QuantityBadge({required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        '$quantity',
        style: const TextStyle(
          color: AppColors.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space2),
          child: Icon(Icons.remove_rounded, size: 16, color: AppColors.error),
        ),
      ),
    );
  }
}
