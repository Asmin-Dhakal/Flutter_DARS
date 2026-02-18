import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CartSummary extends StatelessWidget {
  final List<CartItem> items;
  final int totalItems;
  final double totalAmount;
  final Function(CartItem)? onRemove;

  const CartSummary({
    super.key,
    required this.items,
    required this.totalItems,
    required this.totalAmount,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map(
          (item) => _CartItemTile(
            item: item,
            onRemove: onRemove != null ? () => onRemove!(item) : null,
          ),
        ),
        const Divider(height: AppTokens.space6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                  style: TextStyle(fontSize: 13, color: AppColors.gray600),
                ),
              ],
            ),
            Text(
              'Rs. ${totalAmount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onRemove;

  const _CartItemTile({required this.item, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space2,
              vertical: AppTokens.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Text(
              '${item.quantity}x',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Rs. ${item.price.toStringAsFixed(0)} each',
                  style: TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ),
          Text(
            'Rs. ${item.total.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: AppTokens.space2),
            _RemoveButton(onTap: onRemove!),
          ],
        ],
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
          padding: const EdgeInsets.all(AppTokens.space1),
          child: Icon(Icons.remove_rounded, size: 18, color: AppColors.error),
        ),
      ),
    );
  }
}
