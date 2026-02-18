import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart' as models;
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import 'widgets/menu_item_card.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    // Load menu items when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenuItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Menu'),
            Text(
              'Table ${cartProvider.tableNumber}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (context) => Stack(
              alignment: Alignment.center,
              children: [
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Error Message
          if (menuProvider.error != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      menuProvider.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => menuProvider.loadMenuItems(),
                  ),
                ],
              ),
            ),

          // Category Filter
          if (menuProvider.categories.length > 1)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: menuProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = menuProvider.categories[index];
                  final isSelected = category == menuProvider.selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        menuProvider.selectCategory(category);
                      },
                      selectedColor: Colors.orange.shade800,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Loading or Menu Grid
          Expanded(
            child: menuProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : menuProvider.filteredItems.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => menuProvider.loadMenuItems(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: menuProvider.filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = menuProvider.filteredItems[index];
                        return MenuItemCard(
                          item: item,
                          onTap: () => _showAddToCartDialog(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No menu items available',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showAddToCartDialog(models.MenuItem item) {
    final instructionsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (item.description != null)
                Text(
                  item.description!,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              if (item.itemType != null) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    item.itemType!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.orange.shade50,
                ),
              ],
              const SizedBox(height: 16),

              TextField(
                controller: instructionsController,
                decoration: InputDecoration(
                  labelText: 'Special Instructions',
                  hintText: 'e.g., No onions, extra sauce...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Convert backend MenuItem to cart MenuItem (or update cart provider to use backend model)
                    context.read<CartProvider>().addToCart(
                      models.MenuItem(
                        id: item.id,
                        name: item.name,
                        description: item.description,
                        price: item.price,
                        itemType: item.itemType,
                      ),
                      instructions: instructionsController.text.isEmpty
                          ? null
                          : instructionsController.text,
                    );

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} added to cart'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add to Order',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
