import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/bill.dart';
import '../../../providers/bill_provider.dart';

class AddCustomerItemsModal extends StatefulWidget {
  final String? excludeCustomerId;

  const AddCustomerItemsModal({super.key, this.excludeCustomerId});

  @override
  State<AddCustomerItemsModal> createState() => _AddCustomerItemsModalState();
}

class _AddCustomerItemsModalState extends State<AddCustomerItemsModal> {
  UnbilledCustomer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadUnbilledCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final billProvider = context.watch<BillProvider>();

    // Filter out the customer we're already billing for
    final availableCustomers = billProvider.unbilledCustomers.where((customer) {
      return customer.id != widget.excludeCustomerId;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Customer\'s Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'Select Customer',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            if (billProvider.isLoading && availableCustomers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (availableCustomers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No other customers with unbilled items',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UnbilledCustomer>(
                    isExpanded: true,
                    value: _selectedCustomer,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Choose a customer...'),
                    ),
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.keyboard_arrow_down),
                    ),
                    items: availableCustomers.map((customer) {
                      return DropdownMenuItem<UnbilledCustomer>(
                        value: customer,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customer.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Badge showing remaining unbilled items count
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${customer.totalItemCount}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rs. ${customer.totalUnbilledAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (customer) {
                      setState(() {
                        _selectedCustomer = customer;
                      });
                    },
                  ),
                ),
              ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedCustomer == null
                      ? null
                      : () => Navigator.of(context).pop(_selectedCustomer),
                  child: const Text('Add Items'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
