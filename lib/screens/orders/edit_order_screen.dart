import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../models/menu_item.dart' as models;
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/order_service.dart';
import '../widgets/customer_selector.dart';

class EditOrderScreen extends StatefulWidget {
  final Order order;

  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  Customer? _selectedCustomer;
  final _notesController = TextEditingController();
  final Map<String, int> _cart = {}; // itemId -> quantity
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _initializeFromOrder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenuItems();
    });
  }

  void _initializeFromOrder() {
    // Set customer
    _selectedCustomer = Customer(
      id: widget.order.customerId ?? '',
      name: widget.order.customerName,
    );

    // Set notes
    _notesController.text = widget.order.notes ?? '';

    // Initialize cart from existing order items
    for (final item in widget.order.orderedItems) {
      _cart[item.menuItemId] = item.quantity;
    }
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
        title: const Text('Edit Order'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isUpdating ? null : _updateOrder,
            icon: _isUpdating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Number Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.order.orderNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatDate(widget.order.createdAt)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

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
                    title: 'Order Items',
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

                  // Current Order Summary Card
                  if (_cart.isNotEmpty)
                    _buildSectionCard(
                      title: 'Current Order',
                      icon: Icons.shopping_bag_outlined,
                      child: Column(
                        children: [
                          ..._buildCartItemsList(),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total ($_totalItems items)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Rs. ${_totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Notes Card
                  _buildSectionCard(
                    title: 'Notes',
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

                  const SizedBox(height: 100),
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
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  List<Widget> _buildCartItemsList() {
    final menuProvider = context.read<MenuProvider>();

    return _cart.entries.map((entry) {
      final item = menuProvider.getItemById(entry.key);
      if (item == null) return const SizedBox.shrink();

      final quantity = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${quantity}x',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Rs. ${item.price.toStringAsFixed(0)} each',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${(item.price * quantity).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _removeFromCart(item),
              icon: Icon(Icons.remove_circle, color: Colors.red.shade400),
            ),
          ],
        ),
      );
    }).toList();
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

  Future<void> _updateOrder() async {
    if (_selectedCustomer == null || _cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer and add items'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      // Build orderedItems array for API
      final orderedItems = _cart.entries.map((entry) {
        return {'menuItem': entry.key, 'quantity': entry.value};
      }).toList();

      final updatedOrder = await OrderService.updateOrder(
        orderId: widget.order.id,
        customerId: _selectedCustomer!.id,
        orderedItems: orderedItems,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order ${updatedOrder.orderNumber} updated successfully!',
            ),
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
        setState(() => _isUpdating = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
