import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bill.dart';
import '../../services/menu_service.dart';
import '../../services/auth_service.dart';
import '../../providers/bill_provider.dart';
import 'widgets/add_customer_items_modal.dart';
import 'widgets/components/customer_items_section.dart';
import 'widgets/components/create_bill_controls.dart';
import 'widgets/create_bill_header.dart';
import 'widgets/bill_summary.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/skeleton.dart';

class CreateBillScreen extends StatefulWidget {
  final UnbilledCustomer initialCustomer;

  const CreateBillScreen({super.key, required this.initialCustomer});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final Map<String, List<SelectableBillItem>> _customerItems = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadInitialCustomerItems();
  }

  Future<void> _loadInitialCustomerItems() async {
    setState(() => _isLoading = true);

    final items = await _convertOrdersToItems(
      widget.initialCustomer.orders,
      widget.initialCustomer.id,
      widget.initialCustomer.name,
    );

    setState(() {
      _customerItems[widget.initialCustomer.id] = items;
      _isLoading = false;
    });
  }

  Future<List<SelectableBillItem>> _convertOrdersToItems(
    List<UnbilledOrder> orders,
    String customerId,
    String customerName,
  ) async {
    final List<SelectableBillItem> items = [];
    final Set<String> menuItemIds = {};

    for (final order in orders) {
      for (final orderedItem in order.orderedItems) {
        menuItemIds.add(orderedItem.menuItemId);
      }
    }

    final menuItems = await MenuService.getMenuItemsByIds(menuItemIds.toList());

    for (final order in orders) {
      for (final orderedItem in order.orderedItems) {
        final menuItem = menuItems[orderedItem.menuItemId];
        final item = SelectableBillItem(
          orderId: order.id,
          orderNumber: order.orderNumber,
          menuItemId: orderedItem.menuItemId,
          menuItemName: menuItem?.name ?? 'Unknown Item',
          priceAtOrder: orderedItem.priceAtOrder,
          availableQuantity: orderedItem.quantity - orderedItem.billedQuantity,
          selectedQuantity: orderedItem.quantity - orderedItem.billedQuantity,
          isSelected: true,
          customerId: customerId,
          customerName: customerName,
        );
        items.add(item);
      }
    }

    return items;
  }

  void _addOtherCustomer() async {
    final result = await showDialog<UnbilledCustomer>(
      context: context,
      builder: (context) =>
          AddCustomerItemsModal(excludeCustomerId: widget.initialCustomer.id),
    );

    if (result != null) {
      if (_customerItems.containsKey(result.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.name} is already added', maxLines: 2),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final items = await _convertOrdersToItems(
        result.orders,
        result.id,
        result.name,
      );

      setState(() {
        _customerItems[result.id] = items;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${result.name}\'s items', maxLines: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeCustomer(String customerId) {
    setState(() {
      _customerItems.remove(customerId);
    });
  }

  void _toggleSelectAll(bool select) {
    setState(() {
      for (final items in _customerItems.values) {
        for (final item in items) {
          item.isSelected = select;
          if (select && item.selectedQuantity == 0) {
            item.selectedQuantity = item.availableQuantity;
          }
        }
      }
    });
  }

  Future<void> _createBill() async {
    final selectedItems = _getSelectedItems();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final user = await AuthService.getUser();
      final createdBy = user?.id ?? '';

      if (createdBy.isEmpty) {
        throw Exception('User not authenticated');
      }

      final items = selectedItems
          .map(
            (item) => {
              'order': item.orderId,
              'menuItem': item.menuItemId,
              'quantity': item.selectedQuantity,
            },
          )
          .toList();

      final createdBill = await context.read<BillProvider>().createBill(
        customerId: widget.initialCustomer.id,
        orderedItems: items,
        createdBy: createdBy,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted && createdBill != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bill ${createdBill.billNumber} created successfully',
              maxLines: 2,
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _handleCreateBillError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _handleCreateBillError(String error) {
    String title = 'Error Creating Bill';
    String message = error;

    if (error.contains('Cannot bill') && error.contains('remaining')) {
      final itemMatch = RegExp(
        r'Cannot bill \d+ of "([^"]+)"',
      ).firstMatch(error);
      final remainingMatch = RegExp(r'Only (\d+) remaining').firstMatch(error);
      final pendingMatch = RegExp(
        r'pending in other bills: (\d+)',
      ).firstMatch(error);

      final itemName = itemMatch?.group(1) ?? 'item';
      final remaining = remainingMatch?.group(1) ?? '0';
      final pending = pendingMatch?.group(1) ?? '0';

      title = 'Item Already in Another Bill';
      message =
          '"$itemName" cannot be added.\n'
          '• Remaining: $remaining\n'
          '• In pending bills: $pending\n'
          'Please refresh and try again.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Text(message, maxLines: 5, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<SelectableBillItem> _getSelectedItems() {
    final List<SelectableBillItem> selected = [];
    for (final items in _customerItems.values) {
      selected.addAll(
        items.where((item) => item.isSelected && item.selectedQuantity > 0),
      );
    }
    return selected;
  }

  double get _totalAmount {
    return _getSelectedItems().fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get _selectedItemCount {
    return _getSelectedItems().length;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: EdgeInsets.all(isSmall ? 12 : 20),
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: size.height * 0.9, // Responsive height
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                CreateBillHeader(
                  initialCustomer: widget.initialCustomer,
                  onAddOtherCustomer: _addOtherCustomer,
                  onBack: () => Navigator.of(context).pop(),
                ),

                const Divider(height: 1),

                // Content
                Flexible(
                  child: _isLoading
                      ? _buildSkeleton(isSmall)
                      : _buildContent(isSmall),
                ),

                // Footer
                BillSummary(
                  selectedItemCount: _selectedItemCount,
                  totalAmount: _totalAmount,
                  isCreating: _isCreating,
                  onCreate: _createBill,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isSmall) {
    return Padding(
      padding: EdgeInsets.all(isSmall ? 12 : AppTokens.space4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: isSmall ? 150 : 200, height: isSmall ? 16 : 20),
            SizedBox(height: isSmall ? 12 : AppTokens.space3),
            ...List.generate(
              6,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: isSmall ? 8 : AppTokens.space2,
                ),
                child: SkeletonBox(
                  width: double.infinity,
                  height: isSmall ? 12 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isSmall) {
    if (_customerItems.isEmpty) {
      return const Center(child: Text('No items to bill'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CreateBillControls(
            selectedItemCount: _selectedItemCount,
            isAllSelected: _selectedItemCount > 0,
            onToggleSelectAll: () => _toggleSelectAll(_selectedItemCount == 0),
            notesController: _notesController,
          ),

          SizedBox(height: isSmall ? 12 : 16),

          CustomerItemsSection(
            customerItems: _customerItems,
            primaryCustomerId: widget.initialCustomer.id,
            onRemoveCustomer: _removeCustomer,
            onItemChanged: (updatedItem) {
              setState(() {});
            },
          ),

          SizedBox(height: isSmall ? 16 : 24),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
