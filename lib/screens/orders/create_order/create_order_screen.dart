import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_bottom_sheet.dart';
import '../../../core/widgets/modern_snackbar.dart';
import '../../../models/customer.dart';
import '../../../models/menu_item.dart' as models;
import '../../../providers/menu_provider.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../providers/order_provider.dart';
import '../../../services/order_service.dart';
import '../../../services/firestore_order_service.dart';
import '../../widgets/customer_selector.dart';
import 'components/order_summary_card.dart';
import 'components/menu_grid.dart';
import 'components/category_filter.dart';

/// Modern, modular Create Order Screen
/// Optimized for low-end devices with lazy loading and minimal rebuilds
class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  Customer? _selectedCustomer;
  final _notesController = TextEditingController();
  final Map<String, int> _cart = {};
  bool _isCreating = false;

  // Performance: Cache calculations
  double? _cachedTotal;
  int? _cachedItemCount;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  void _loadMenuItems() {
    // Defer to next frame for better startup performance
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
    _cachedItemCount ??= _cart.values.fold<int>(0, (a, b) => a + b);
    return _cachedItemCount!;
  }

  // Get cart items with details for the cart summary
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

  // Invalidate cache when cart changes
  void _invalidateCache() {
    _cachedTotal = null;
    _cachedItemCount = null;
  }

  bool get _canCreate => _selectedCustomer != null && _cart.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(
        title: const Text('Create Order'),
        centerTitle: false,
        actions: [
          // Quick clear button
          if (_cart.isNotEmpty)
            TextButton.icon(
              onPressed: _clearCart,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
        ],
      ),
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Section
                        _CustomerSection(
                          selectedCustomer: _selectedCustomer,
                          onSelect: (customer) {
                            setState(() => _selectedCustomer = customer);
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

                        // Cart Summary Section (shows when cart has items)
                        if (_cart.isNotEmpty) ...[
                          _CartSection(
                            items: _cartItems,
                            totalItems: _totalItems,
                            totalAmount: _totalAmount,
                            onRemoveItem: _removeItemCompletely,
                            onUpdateQuantity: _updateItemQuantity,
                          ),
                          const SizedBox(height: AppTokens.space5),
                        ],

                        // Notes Section
                        _NotesSection(controller: _notesController),

                        // Bottom padding for safe area
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          ModernBottomBar(
            child: _BuildOrderButton(
              isLoading: _isCreating,
              isEnabled: _canCreate,
              itemCount: _totalItems,
              totalAmount: _totalAmount,
              onPressed: _createOrder,
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

  void _updateItemQuantity(String itemId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cart.remove(itemId);
      } else {
        _cart[itemId] = newQuantity;
      }
      _invalidateCache();
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _invalidateCache();
    });
  }

  Future<void> _createOrder() async {
    if (!_canCreate) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isCreating = true);

    try {
      final orderedItems = _cart.entries.map((entry) {
        return {'menuItem': entry.key, 'quantity': entry.value};
      }).toList();

      final order = await OrderService.createOrder(
        customerId: _selectedCustomer!.id,
        orderedItems: orderedItems,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Save to Firestore for real-time notifications
      await FirestoreOrderService().saveOrderToFirestore(order);

      if (mounted) {
        ModernSnackBar.success(
          context,
          'Order ${order.orderNumber} created successfully!',
        );
        context.read<OrderProvider>().loadOrders();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.error(context, 'Failed to create order: $e');
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}

// ==================== CART ITEM MODEL ====================

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}

// ==================== SECTION WIDGETS ====================

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
      title: 'Menu Items',
      icon: Icons.restaurant_menu_rounded,
      isComplete: cart.isNotEmpty,
      badge: cart.isNotEmpty
          ? '${cart.values.fold(0, (a, b) => a + b)} items'
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Filter
          if (menuProvider.categories.length > 1)
            CategoryFilter(
              categories: menuProvider.categories,
              selectedCategory: menuProvider.selectedCategory,
              onSelect: menuProvider.selectCategory,
            ),
          if (menuProvider.categories.length > 1)
            const SizedBox(height: AppTokens.space4),

          // Menu Content
          _buildMenuContent(),
        ],
      ),
    );
  }

  Widget _buildMenuContent() {
    if (menuProvider.isLoading) {
      // Show a responsive skeleton grid while menu items load
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

    if (menuProvider.filteredItems.isEmpty) {
      return const _EmptyState(
        icon: Icons.no_food_outlined,
        message: 'No items available',
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

// ==================== CART SECTION ====================

class _CartSection extends StatelessWidget {
  final List<CartItem> items;
  final int totalItems;
  final double totalAmount;
  final Function(String) onRemoveItem;
  final Function(String, int) onUpdateQuantity;

  const _CartSection({
    required this.items,
    required this.totalItems,
    required this.totalAmount,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Current Items',
      icon: Icons.shopping_bag_outlined,
      isComplete: true,
      badge: '$totalItems items',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart Items List
          ...items.map(
            (item) => _CartItemTile(
              item: item,
              onRemove: () => onRemoveItem(item.id),
              onIncrease: () => onUpdateQuantity(item.id, item.quantity + 1),
              onDecrease: () => onUpdateQuantity(item.id, item.quantity - 1),
            ),
          ),

          const Divider(height: 24),

          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ($totalItems items)',
                style: TextStyle(fontSize: 14, color: AppColors.gray600),
              ),
              Text(
                'Rs. ${totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs. ${item.price.toStringAsFixed(0)} x ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Row(
            children: [
              _QuantityButton(icon: Icons.remove, onTap: onDecrease),
              const SizedBox(width: 8),
              Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              _QuantityButton(icon: Icons.add, onTap: onIncrease),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
      ),
    );
  }
}

// ==================== OTHER SECTIONS ====================

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

class _BuildOrderButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final int itemCount;
  final double totalAmount;
  final VoidCallback onPressed;

  const _BuildOrderButton({
    required this.isLoading,
    required this.isEnabled,
    required this.itemCount,
    required this.totalAmount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Order Summary (only show when has items)
        if (itemCount > 0) ...[
          OrderSummaryCard(itemCount: itemCount, totalAmount: totalAmount),
          const SizedBox(height: AppTokens.space3),
        ],

        // Create Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: isEnabled && !isLoading ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.onSuccess,
              disabledBackgroundColor: AppColors.gray300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: SkeletonBox(
                      width: 20,
                      height: 20,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: AppTokens.space2),
                      Text(
                        itemCount > 0 ? 'Create Order' : 'Select Items',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ==================== SHARED COMPONENTS ====================

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
          // Header
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
          // Content
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space8),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.gray400),
            const SizedBox(height: AppTokens.space3),
            Text(message, style: TextStyle(color: AppColors.gray600)),
          ],
        ),
      ),
    );
  }
}
