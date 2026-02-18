import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bill.dart';
import '../../services/menu_service.dart';
import '../../services/auth_service.dart';
import '../../services/bill_service.dart';
import 'widgets/add_customer_items_modal.dart';

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

    // Convert initial customer's orders to selectable items
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

    // Collect all menu item IDs
    for (final order in orders) {
      for (final orderedItem in order.orderedItems) {
        menuItemIds.add(orderedItem.menuItemId);
      }
    }

    // Fetch menu item names - use static method
    final menuItems = await MenuService.getMenuItemsByIds(menuItemIds.toList());

    // Create selectable items
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
          selectedQuantity:
              orderedItem.quantity -
              orderedItem.billedQuantity, // Default to all
          isSelected: true, // Default selected
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
      builder: (context) => AddCustomerItemsModal(
        excludeCustomerId:
            widget.initialCustomer.id, // Pass current customer ID
      ),
    );

    if (result != null) {
      // Check if already added
      if (_customerItems.containsKey(result.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.name} is already added'),
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
          content: Text('Added ${result.name}\'s items'),
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
      final billService = context.read<BillService>();
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

      final bill = await billService.createBill(
        customerId: widget.initialCustomer.id,
        items: items,
        createdBy: createdBy,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill ${bill.billNumber} created successfully'),
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
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _handleCreateBillError(String error) {
    String title = 'Error Creating Bill';
    String message = error;
    List<Widget> actions = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ];

    // Parse specific error messages
    if (error.contains('Cannot bill') && error.contains('remaining')) {
      // Extract item name and order number using regex
      final itemMatch = RegExp(
        r'Cannot bill \d+ of "([^"]+)"',
      ).firstMatch(error);
      final orderMatch = RegExp(r'from order ([^\.]+)').firstMatch(error);
      final remainingMatch = RegExp(r'Only (\d+) remaining').firstMatch(error);
      final pendingMatch = RegExp(
        r'pending in other bills: (\d+)',
      ).firstMatch(error);

      final itemName = itemMatch?.group(1) ?? 'item';
      final orderNumber = orderMatch?.group(1) ?? 'unknown';
      final remaining = remainingMatch?.group(1) ?? '0';
      final pending = pendingMatch?.group(1) ?? '0';

      title = 'Item Already in Another Bill';
      message =
          '"$itemName" from $orderNumber cannot be added to this bill.\n\n'
          '• Remaining quantity: $remaining\n'
          '• Already in pending bills: $pending\n\n'
          'Please refresh and try again, or select a different item.';

      actions = [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Go Back'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Refresh and retry
            _refreshAndRetry();
          },
          child: const Text('Refresh & Retry'),
        ),
      ];
    } else if (error.contains('Bad Request')) {
      title = 'Invalid Request';
      message =
          'Some items may have been billed already. Please refresh the data and try again.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: actions,
      ),
    );
  }

  Future<void> _refreshAndRetry() async {
    // Close current screen and go back to customer selection
    Navigator.of(context).pop(false);

    // Show refresh indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing data...'),
        duration: Duration(seconds: 1),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(theme),

              const Divider(height: 1),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(theme),
              ),

              // Footer
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Bill - Select Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Bill for: ${widget.initialCustomer.name}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _addOtherCustomer,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Others'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_customerItems.isEmpty) {
      return const Center(child: Text('No items to bill'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select All / Deselect All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Items to Bill',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => _toggleSelectAll(_selectedItemCount == 0),
                child: Text(
                  _selectedItemCount == 0 ? 'Select All' : 'Deselect All',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Customer Items
          ..._customerItems.entries.map((entry) {
            return _buildCustomerSection(entry.key, entry.value, theme);
          }),

          const SizedBox(height: 24),

          // Notes
          Text(
            'Notes (optional)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any notes for this bill...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(
    String customerId,
    List<SelectableBillItem> items,
    ThemeData theme,
  ) {
    final customerName = items.first.customerName;
    final isPrimaryCustomer = customerId == widget.initialCustomer.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              customerName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isPrimaryCustomer)
              TextButton.icon(
                onPressed: () => _removeCustomer(customerId),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _buildItemTile(item, theme)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItemTile(SelectableBillItem item, ThemeData theme) {
    final bool isFullyBilled = item.availableQuantity == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFullyBilled ? Colors.grey[100] : Colors.white,
        border: Border.all(
          color: isFullyBilled ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Show checkmark or disabled state
          isFullyBilled
              ? Icon(Icons.check_circle, color: Colors.green[400], size: 24)
              : Checkbox(
                  value: item.isSelected,
                  onChanged: (value) {
                    setState(() {
                      item.isSelected = value ?? false;
                      if (item.isSelected && item.selectedQuantity == 0) {
                        item.selectedQuantity = item.availableQuantity;
                      }
                    });
                  },
                ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.menuItemName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isFullyBilled ? Colors.grey : Colors.black,
                        decoration: isFullyBilled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (isFullyBilled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Billed',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.orderNumber} · Rs. ${item.priceAtOrder.toStringAsFixed(0)} each',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFullyBilled
                        ? Colors.grey[400]
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Show quantity or "Billed" text
          isFullyBilled
              ? Text(
                  'Billed',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        controller: TextEditingController(
                          text: item.selectedQuantity.toString(),
                        ),
                        onChanged: (value) {
                          final qty = int.tryParse(value) ?? 0;
                          setState(() {
                            item.selectedQuantity = qty.clamp(
                              0,
                              item.availableQuantity,
                            );
                            item.isSelected = item.selectedQuantity > 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${item.availableQuantity}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_selectedItemCount items selected',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                'Total: Rs. ${_totalAmount.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _isCreating ? null : _createBill,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Create Bill'),
          ),
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
