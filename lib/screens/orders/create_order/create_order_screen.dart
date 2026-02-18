import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_bottom_sheet.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../core/widgets/modern_snackbar.dart';
import '../../../models/customer.dart';
import '../../../models/menu_item.dart' as models;
import '../../../providers/menu_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../services/order_service.dart';
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

  // Invalidate cache when cart changes
  void _invalidateCache() {
    _cachedTotal = null;
    _cachedItemCount = null;
  }

  int get _currentStep {
    if (_selectedCustomer == null) return 0;
    if (_cart.isEmpty) return 1;
    return 2;
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
          // Progress Steps
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(AppTokens.space4),
            child: StepIndicator(
              currentStep: _currentStep,
              steps: const [
                StepItem(label: 'Customer', icon: Icons.person_outline),
                StepItem(label: 'Items', icon: Icons.restaurant_menu),
                StepItem(label: 'Confirm', icon: Icons.check),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.outline.withOpacity(0.3)),

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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.space8),
          child: CircularProgressIndicator(strokeWidth: 2),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onSuccess,
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
