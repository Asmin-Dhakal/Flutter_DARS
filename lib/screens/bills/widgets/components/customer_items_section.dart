import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/bill.dart';
import 'bill_item_card.dart';

typedef RemoveCustomerCallback = void Function(String customerId);

class CustomerItemsSection extends StatelessWidget {
  final Map<String, List<SelectableBillItem>> customerItems;
  final String primaryCustomerId;
  final RemoveCustomerCallback onRemoveCustomer;
  final ValueChanged<SelectableBillItem> onItemChanged;

  const CustomerItemsSection({
    super.key,
    required this.customerItems,
    required this.primaryCustomerId,
    required this.onRemoveCustomer,
    required this.onItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = customerItems.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        final customerId = entry.key;
        final items = entry.value;
        final customerName = items.first.customerName;
        final isPrimary = customerId == primaryCustomerId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customerName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (!isPrimary)
                  TextButton.icon(
                    onPressed: () => onRemoveCustomer(customerId),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            ...items.map(
              (item) => BillItemCard(
                item: item,
                onSelectChanged: (selected) {
                  item.isSelected = selected;
                  if (selected && item.selectedQuantity == 0) {
                    item.selectedQuantity = item.availableQuantity;
                  }
                  onItemChanged(item);
                },
                onQuantityChanged: (qty) {
                  item.selectedQuantity = qty.clamp(0, item.availableQuantity);
                  item.isSelected = item.selectedQuantity > 0;
                  onItemChanged(item);
                },
              ),
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        );
      }).toList(),
    );
  }
}
