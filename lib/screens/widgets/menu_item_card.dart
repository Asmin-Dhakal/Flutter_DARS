import 'package:flutter/material.dart';
import '../../models/menu_item.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const MenuItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for food image (since no pictures)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(item.itemType),
                  size: 40,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      if (item.itemType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.itemType!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? itemType) {
    if (itemType == null) return Icons.restaurant_menu;

    final type = itemType.toLowerCase();
    if (type.contains('drink') || type.contains('beverage')) {
      return Icons.local_drink;
    }
    if (type.contains('dessert')) return Icons.cake;
    if (type.contains('main') || type.contains('entree')) {
      return Icons.restaurant;
    }
    if (type.contains('appetizer') || type.contains('starter')) {
      return Icons.tapas;
    }
    if (type.contains('breakfast')) return Icons.breakfast_dining;
    if (type.contains('lunch')) return Icons.lunch_dining;
    if (type.contains('dinner')) return Icons.dinner_dining;
    if (type.contains('snack')) return Icons.cookie;
    return Icons.restaurant_menu;
  }
}
