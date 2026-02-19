import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/bill.dart';
import '../../../providers/bill_provider.dart';
import '../../../core/widgets/skeleton.dart';

class CreateBillModal extends StatefulWidget {
  const CreateBillModal({super.key});

  @override
  State<CreateBillModal> createState() => _CreateBillModalState();
}

class _CreateBillModalState extends State<CreateBillModal> {
  UnbilledCustomer? _selectedCustomer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // DEFER loading to after build completes - FIXES THE ERROR
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
    });
  }

  Future<void> _loadCustomers() async {
    // Check mounted before setState
    if (!mounted) return;

    setState(() => _isLoading = true);

    // Use read instead of watch to avoid triggering rebuild during build
    await context.read<BillProvider>().loadUnbilledCustomers();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    final billProvider = context.watch<BillProvider>();
    final customers = billProvider.unbilledCustomers;

    // Filter out customers with no actual unbilled items
    final availableCustomers = customers
        .where((c) => c.totalItemCount > 0)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      ),
      child: Container(
        width: isSmall ? size.width * 0.9 : 400,
        constraints: BoxConstraints(
          maxHeight: isSmall ? size.height * 0.8 : 500,
        ),
        padding: EdgeInsets.all(isSmall ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isSmall
                        ? 'Select Customer'
                        : 'Create Bill - Select Customer',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmall ? 18 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 16 : 20),

            if (_isLoading || billProvider.isLoading)
              _buildSkeleton(isSmall)
            else if (availableCustomers.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Customer',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        fontSize: isSmall ? 13 : null,
                      ),
                    ),
                    SizedBox(height: isSmall ? 10 : 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: availableCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = availableCustomers[index];
                          return _buildCustomerCard(customer, theme, isSmall);
                        },
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: isSmall ? 12 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: isSmall ? 8 : 12),
                ElevatedButton(
                  onPressed: _selectedCustomer == null
                      ? null
                      : () => Navigator.of(context).pop(_selectedCustomer),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isSmall) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(height: isSmall ? 6 : 8),
          SkeletonBox(width: double.infinity, height: isSmall ? 16 : 18),
          SizedBox(height: isSmall ? 10 : 12),
          ...List.generate(
            4,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: isSmall ? 6 : 8),
              child: SkeletonBox(
                width: double.infinity,
                height: isSmall ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No customers with unbilled items',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCustomers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
    UnbilledCustomer customer,
    ThemeData theme,
    bool isSmall,
  ) {
    final isSelected = _selectedCustomer?.id == customer.id;

    return Card(
      margin: EdgeInsets.only(bottom: isSmall ? 6 : 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCustomer = customer;
          });
        },
        borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmall ? 14 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmall ? 2 : 4),
                    Text(
                      '${customer.orderCount} order(s)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmall ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 6 : 8,
                  vertical: isSmall ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${customer.totalItemCount}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall ? 11 : 12,
                      ),
                    ),
                    if (!isSmall)
                      Text(
                        ' items',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: isSmall ? 6 : 8),
              // Amount
              Flexible(
                child: Text(
                  'Rs. ${customer.totalUnbilledAmount.toStringAsFixed(0)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 13 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
