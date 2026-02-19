import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_snackbar.dart';
import '../../../models/customer.dart';
import '../../../models/order.dart';
import '../../../models/menu_item.dart' as models;
import '../../../providers/menu_provider.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../providers/order_provider.dart';
import '../../../services/order_service.dart';
import '../../widgets/customer_selector.dart';
import '../create_order/components/menu_grid.dart';
import '../create_order/components/category_filter.dart';
import '../create_order/components/order_header.dart';
import 'components/cart_summary.dart';

/// Modern Edit Order Screen
/// Modular design matching CreateOrderScreen architecture
class EditOrderScreen extends StatefulWidget {
  final Order order;

  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  Customer? _selectedCustomer;
  final _notesController = TextEditingController();
  final Map<String, int> _cart = {};
  bool _isUpdating = false;

  // Performance: Cache calculations
  double? _cachedTotal;
  int? _cachedItemCount;

  @override
  void initState() {
    super.initState();
    _initializeFromOrder();
    _loadMenuItems();
  }

  void _initializeFromOrder() {
    _selectedCustomer = Customer(
      id: widget.order.customerId ?? '',
      name: widget.order.customerName,
    );
    _notesController.text = widget.order.notes ?? '';

    for (final item in widget.order.orderedItems) {
      _cart[item.menuItemId] = item.quantity;
    }
  }

  void _loadMenuItems() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenuItems();
    });
  }

  double get _totalAmount {
    if (_cachedTotal != null) return _cachedTotal!;

    final menuProvider = context.read<MenuProvider>();
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = menuProvider.getItemById(itemId);
      if (item != null) total += item.price * quantity;
    });
    _cachedTotal = total;
    return total;
  }

  int get _totalItems {
    _cachedItemCount ??= _cart.values.fold<int>(0, (sum, qty) => sum + qty);
    return _cachedItemCount!;
  }

  void _invalidateCache() {
    _cachedTotal = null;
    _cachedItemCount = null;
  }

  List<CartItem> get _cartItems {
    final menuProvider = context.read<MenuProvider>();
    return _cart.entries.map((entry) {
      final item = menuProvider.getItemById(entry.key);
      return CartItem(
        id: entry.key,
        name: item?.name ?? 'Unknown Item',
        price: item?.price ?? 0,
        quantity: entry.value,
      );
    }).toList();
  }

  bool get _hasChanges {
    // Check if customer changed
    if (_selectedCustomer?.id != widget.order.customerId) return true;

    // Check if notes changed
    if ((_notesController.text.trim()) != (widget.order.notes ?? '')) {
      return true;
    }

    // Check if items changed
    if (_cart.length != widget.order.orderedItems.length) return true;

    for (final item in widget.order.orderedItems) {
      if (_cart[item.menuItemId] != item.quantity) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(
        title: const Text('Edit Order'),
        centerTitle: false,
        actions: [
          // Reset button
          if (_hasChanges)
            TextButton.icon(
              onPressed: _resetToOriginal,
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Reset'),
              style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            ),
          const SizedBox(width: AppTokens.space2),
          // Save button
          _SaveButton(
            isLoading: _isUpdating,
            isEnabled:
                _hasChanges && _selectedCustomer != null && _cart.isNotEmpty,
            onPressed: _updateOrder,
          ),
          const SizedBox(width: AppTokens.space4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Header
                        OrderHeader(
                          orderNumber: widget.order.orderNumber,
                          createdAt: widget.order.createdAt,
                          status: widget.order.status,
                        ),
                        const SizedBox(height: AppTokens.space5),

                        // Customer Section
                        _CustomerSection(
                          selectedCustomer: _selectedCustomer,
                          onSelect: (customer) {
                            setState(() {
                              _selectedCustomer = customer;
                              _invalidateCache();
                            });
                          },
                        ),
                        const SizedBox(height: AppTokens.space5),

                        // Menu Section
                        _MenuSection(
                          menuProvider: menuProvider,
                          cart: _cart,
                          onAdd: _addToCart,
                          onRemove: _removeFromCart,
                        ),
                        const SizedBox(height: AppTokens.space5),

                        // Cart Summary (if has items)
                        if (_cart.isNotEmpty)
                          _CartSection(
                            items: _cartItems,
                            totalItems: _totalItems,
                            totalAmount: _totalAmount,
                            onRemoveItem: (item) =>
                                _removeItemCompletely(item.id),
                          ),
                        if (_cart.isNotEmpty)
                          const SizedBox(height: AppTokens.space5),

                        // Notes Section
                        _NotesSection(controller: _notesController),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(models.MenuItem item) {
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
      _invalidateCache();
    });
  }

  void _removeFromCart(models.MenuItem item) {
    setState(() {
      final currentQty = _cart[item.id] ?? 0;
      if (currentQty <= 1) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = currentQty - 1;
      }
      _invalidateCache();
    });
  }

  void _removeItemCompletely(String itemId) {
    setState(() {
      _cart.remove(itemId);
      _invalidateCache();
    });
  }

  void _resetToOriginal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'This will revert all your changes to the original order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _cart.clear();
                _initializeFromOrder();
                _invalidateCache();
              });
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrder() async {
    if (_selectedCustomer == null || _cart.isEmpty) {
      ModernSnackBar.show(
        context: context,
        message: 'Please select a customer and add items',
        icon: Icons.warning_amber_rounded,
        backgroundColor: AppColors.warning,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isUpdating = true);

    try {
      final orderedItems = _cart.entries.map((entry) {
        return {'menuItem': entry.key, 'quantity': entry.value};
      }).toList();

      final updatedOrder = await OrderService.updateOrder(
        orderId: widget.order.id,
        customerId: _selectedCustomer!.id,
        orderedItems: orderedItems,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ModernSnackBar.success(
          context,
          'Order ${updatedOrder.orderNumber} updated successfully!',
        );
        context.read<OrderProvider>().loadOrders();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.error(context, 'Failed to update order: $e');
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}

// Section Widgets

class _CustomerSection extends StatelessWidget {
  final Customer? selectedCustomer;
  final Function(Customer) onSelect;

  const _CustomerSection({
    required this.selectedCustomer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Customer',
      icon: Icons.person_outline_rounded,
      isComplete: selectedCustomer != null,
      child: CustomerSelector(
        selectedCustomer: selectedCustomer,
        onSelect: onSelect,
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final MenuProvider menuProvider;
  final Map<String, int> cart;
  final Function(models.MenuItem) onAdd;
  final Function(models.MenuItem) onRemove;

  const _MenuSection({
    required this.menuProvider,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Add Items',
      icon: Icons.restaurant_menu_rounded,
      badge: cart.isNotEmpty ? '${cart.length} types' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (menuProvider.categories.length > 1)
            CategoryFilter(
              categories: menuProvider.categories,
              selectedCategory: menuProvider.selectedCategory,
              onSelect: menuProvider.selectCategory,
            ),
          if (menuProvider.categories.length > 1)
            const SizedBox(height: AppTokens.space4),

          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (menuProvider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
        child: Wrap(
          spacing: AppTokens.space3,
          runSpacing: AppTokens.space3,
          children: List.generate(6, (index) {
            return SizedBox(
              width:
                  (MediaQueryData.fromView(
                        WidgetsBinding.instance.window,
                      ).size.width -
                      (AppTokens.space4 * 2) -
                      AppTokens.space3) /
                  2,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  side: BorderSide(color: AppColors.outline.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: double.infinity, height: 110),
                      SizedBox(height: AppTokens.space3),
                      SkeletonBox(width: 120, height: 14),
                      SizedBox(height: AppTokens.space2),
                      SkeletonBox(width: 80, height: 14),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    if (menuProvider.error != null) {
      return _ErrorState(
        message: menuProvider.error!,
        onRetry: menuProvider.loadMenuItems,
      );
    }

    return MenuGrid(
      items: menuProvider.filteredItems,
      cart: cart,
      onAdd: onAdd,
      onRemove: onRemove,
    );
  }
}

class _CartSection extends StatelessWidget {
  final List<CartItem> items;
  final int totalItems;
  final double totalAmount;
  final Function(CartItem) onRemoveItem;

  const _CartSection({
    required this.items,
    required this.totalItems,
    required this.totalAmount,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Current Items',
      icon: Icons.shopping_bag_outlined,
      isComplete: true,
      child: CartSummary(
        items: items,
        totalItems: totalItems,
        totalAmount: totalAmount,
        onRemove: onRemoveItem,
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final TextEditingController controller;

  const _NotesSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Notes',
      icon: Icons.notes_rounded,
      isOptional: true,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Any special instructions...',
          hintStyle: TextStyle(color: AppColors.gray500),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(AppTokens.space4),
        ),
        maxLines: 3,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      icon: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: SkeletonBox(
                width: 18,
                height: 18,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            )
          : const Icon(Icons.save_outlined, size: 18),
      label: const Text('Save'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.onSuccess,
        disabledBackgroundColor: AppColors.gray300,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
      ),
    );
  }
}

// Shared Components

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isComplete;
  final bool isOptional;
  final String? badge;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.isComplete = false,
    this.isOptional = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        side: BorderSide(color: AppColors.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space4,
              vertical: AppTokens.space3,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTokens.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isOptional)
                  Text(
                    'Optional',
                    style: TextStyle(fontSize: 12, color: AppColors.gray500),
                  )
                else if (isComplete)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  )
                else if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusSmall,
                      ),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: AppTokens.space3),
            Text(
              message,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space3),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
