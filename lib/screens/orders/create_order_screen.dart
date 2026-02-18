import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/menu_item.dart' as models;
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/order_service.dart';
import '../widgets/customer_selector.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  Customer? _selectedCustomer;
  final _notesController = TextEditingController();
  final Map<String, int> _cart = {}; // itemId -> quantity
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenuItems();
    });
  }

  double get _totalAmount {
    final menuProvider = context.read<MenuProvider>();
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = menuProvider.getItemById(itemId);
      if (item != null) {
        total += item.price * quantity;
      }
    });
    return total;
  }

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Create New Order'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Selection Card
                  _buildSectionCard(
                    title: 'Customer',
                    icon: Icons.person_outline,
                    child: CustomerSelector(
                      selectedCustomer: _selectedCustomer,
                      onSelect: (customer) {
                        setState(() => _selectedCustomer = customer);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Menu Items Card
                  _buildSectionCard(
                    title: 'Menu Items',
                    icon: Icons.restaurant_menu,
                    child: Column(
                      children: [
                        // Category Chips
                        if (menuProvider.categories.length > 1)
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: menuProvider.categories.length,
                              itemBuilder: (context, index) {
                                final category = menuProvider.categories[index];
                                final isSelected =
                                    category == menuProvider.selectedCategory;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      menuProvider.selectCategory(category);
                                    },
                                    selectedColor: Colors.orange.shade800,
                                    checkmarkColor: Colors.white,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Menu Grid
                        if (menuProvider.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (menuProvider.error != null)
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  menuProvider.error!,
                                  style: TextStyle(color: Colors.red),
                                ),
                                ElevatedButton(
                                  onPressed: () => menuProvider.loadMenuItems(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        else
                          _buildMenuGrid(menuProvider.filteredItems),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes Card
                  _buildSectionCard(
                    title: 'Notes (Optional)',
                    icon: Icons.notes,
                    child: TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Any special instructions...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 3,
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),

          // Bottom Summary Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Order Summary
                  if (_cart.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_totalItems items selected',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Total: Rs. ${_totalAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Create Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _isCreating ||
                              _selectedCustomer == null ||
                              _cart.isEmpty
                          ? null
                          : _createOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Create Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(List<models.MenuItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final quantity = _cart[item.id] ?? 0;

        return InkWell(
          onTap: () => _addToCart(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: quantity > 0 ? Colors.orange.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: quantity > 0
                    ? Colors.orange.shade800
                    : Colors.grey.shade300,
                width: quantity > 0 ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (quantity > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs. ${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (quantity > 0)
                      GestureDetector(
                        onTap: () => _removeFromCart(item),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addToCart(models.MenuItem item) {
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
    });
  }

  void _removeFromCart(models.MenuItem item) {
    setState(() {
      if (_cart[item.id] == 1) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = _cart[item.id]! - 1;
      }
    });
  }

  Future<void> _createOrder() async {
    if (_selectedCustomer == null || _cart.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      // Build orderedItems array for API
      final orderedItems = _cart.entries.map((entry) {
        return {'menuItem': entry.key, 'quantity': entry.value};
      }).toList();

      final order = await OrderService.createOrder(
        customerId: _selectedCustomer!.id,
        orderedItems: orderedItems,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${order.orderNumber} created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh orders list
        context.read<OrderProvider>().loadOrders();

        // Go back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
