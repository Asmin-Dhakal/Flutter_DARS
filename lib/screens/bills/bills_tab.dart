import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bill.dart';
import '../../providers/bill_provider.dart';
import 'widgets/bill_card.dart';
import 'widgets/create_bill_modal.dart';
import 'widgets/empty_bills_state.dart';
import 'widgets/status_filter.dart';
import '../../core/widgets/skeleton.dart';
import 'widgets/bill_pagination.dart';
import 'create_bill_screen.dart';

class BillsTab extends StatefulWidget {
  const BillsTab({super.key});

  @override
  State<BillsTab> createState() => _BillsTabState();
}

class _BillsTabState extends State<BillsTab> {
  String _selectedStatus = 'pending';
  final List<String> _statusOptions = [
    'all',
    'pending',
    'paid',
    'partially_paid',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBills();
    });
  }

  Future<void> _loadBills() async {
    try {
      await context.read<BillProvider>().loadBillsFiltered(
        page: 1,
        limit: 10,
        paymentStatus: _selectedStatus == 'all' ? null : _selectedStatus,
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading bills: $e');
      }
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    // Reset to page 1 when filter changes
    context.read<BillProvider>().loadBillsFiltered(
      page: 1,
      limit: 10,
      paymentStatus: status == 'all' ? null : status,
    );
  }

  Future<void> _deleteBill(Bill bill) async {
    final success = await context.read<BillProvider>().deleteBill(bill.id!);

    if (!mounted) return;

    if (success) {
      _showSuccessSnackBar('${bill.billNumber} deleted successfully');
    } else {
      _loadBills();
      _showErrorSnackBar('Error: ${context.read<BillProvider>().error}');
    }
  }

  void _onPaymentSuccess(Bill bill) {
    _showSuccessSnackBar('Payment for ${bill.billNumber} confirmed!');
    _loadBills();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showCreateBillFlow() async {
    final billProvider = context.read<BillProvider>();
    await billProvider.loadUnbilledCustomers();

    if (!mounted) return;

    final customer = await showDialog<UnbilledCustomer>(
      context: context,
      builder: (context) => const CreateBillModal(),
    );

    if (customer != null && mounted) {
      final created = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CreateBillScreen(initialCustomer: customer),
      );

      if (created == true && mounted) {
        _showSuccessSnackBar('Bill created successfully');
        await _loadBills();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: RefreshIndicator(
        onRefresh: _loadBills,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(isSmall),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 12 : AppTokens.space4,
                  vertical: isSmall ? 12 : AppTokens.space4,
                ),
                child: StatusFilter(
                  selectedStatus: _selectedStatus,
                  statusOptions: _statusOptions,
                  onStatusChanged: _onStatusChanged,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: isSmall ? 8 : AppTokens.space2),
            ),
            if (billProvider.isLoading && billProvider.bills.isEmpty)
              _buildSkeletonList(isSmall)
            else if (billProvider.bills.isEmpty)
              SliverFillRemaining(
                child: EmptyBillsState(onCreateBill: _showCreateBillFlow),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final bill = billProvider.bills[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 12 : AppTokens.space4,
                      vertical: isSmall ? 6 : 0,
                    ),
                    child: BillCard(
                      bill: bill,
                      onDelete: () => _deleteBill(bill),
                      onPay: () => _onPaymentSuccess(bill),
                      onPayWithBill: (b) => _onPaymentSuccess(b),
                    ),
                  );
                }, childCount: billProvider.bills.length),
              ),
            // Add pagination widget at the bottom of the list
            SliverToBoxAdapter(
              child: billProvider.isLoading
                  ? const SizedBox.shrink()
                  : const BillPagination(),
            ),
            // Bottom spacing for FAB
            SliverToBoxAdapter(child: SizedBox(height: isSmall ? 80 : 100)),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(isSmall),
    );
  }

  Widget _buildAppBar(bool isSmall) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : AppTokens.space4,
          vertical: isSmall ? 12 : AppTokens.space4,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bills',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                fontSize: isSmall ? 16 : 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList(bool isSmall) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : AppTokens.space4,
            vertical: isSmall ? 8 : AppTokens.space3,
          ),
          child: Container(
            padding: EdgeInsets.all(isSmall ? 12 : AppTokens.space4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonBox(
                      width: isSmall ? 80 : 100,
                      height: isSmall ? 14 : 16,
                    ),
                    SizedBox(width: isSmall ? 8 : AppTokens.space3),
                    SkeletonBox(
                      width: isSmall ? 50 : 60,
                      height: isSmall ? 12 : 14,
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? 10 : AppTokens.space3),
                SkeletonBox(width: double.infinity, height: isSmall ? 12 : 14),
                SizedBox(height: isSmall ? 6 : AppTokens.space2),
                SkeletonBox(
                  width: isSmall ? 200 : double.infinity,
                  height: isSmall ? 12 : 14,
                ),
                SizedBox(height: isSmall ? 10 : AppTokens.space3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(
                      width: isSmall ? 100 : 120,
                      height: isSmall ? 32 : 36,
                    ),
                    SkeletonBox(
                      width: isSmall ? 70 : 80,
                      height: isSmall ? 32 : 36,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }, childCount: isSmall ? 3 : 4),
    );
  }

  Widget _buildFAB(bool isSmall) {
    return FloatingActionButton.extended(
      onPressed: _showCreateBillFlow,
      icon: const Icon(Icons.add, size: 20),
      label: Text(
        isSmall ? 'New' : 'Create Bill',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      extendedPadding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
    );
  }
}
