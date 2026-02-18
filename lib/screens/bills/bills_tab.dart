import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bill.dart';
import '../../providers/bill_provider.dart';
import '../../services/bill_service.dart';
import 'widgets/bill_card.dart';
import 'widgets/create_bill_modal.dart';
import 'widgets/empty_bills_state.dart';
import 'widgets/status_filter.dart';
import 'create_bill_screen.dart';

class BillsTab extends StatefulWidget {
  const BillsTab({Key? key}) : super(key: key);

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
      final bills = await context.read<BillService>().getAllBills(
        page: 1,
        limit: 10,
        paymentStatus: _selectedStatus == 'all' ? null : _selectedStatus,
      );

      if (mounted) {
        context.read<BillProvider>().setBills(bills);
      }
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
    _loadBills();
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
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showCreateBillFlow() async {
    // Force refresh unbilled customers before showing modal
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

    return Scaffold(
      body: Column(
        children: [
          // Status Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatusFilter(
              selectedStatus: _selectedStatus,
              statusOptions: _statusOptions,
              onStatusChanged: _onStatusChanged,
            ),
          ),

          // Bills List
          Expanded(child: _buildBody(billProvider)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBillFlow,
        icon: const Icon(Icons.add),
        label: const Text('Create Bill'),
      ),
    );
  }

  Widget _buildBody(BillProvider provider) {
    if (provider.isLoading && provider.bills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.bills.isEmpty) {
      return EmptyBillsState(onCreateBill: _showCreateBillFlow);
    }

    return RefreshIndicator(
      onRefresh: _loadBills,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.bills.length,
        itemBuilder: (context, index) {
          final bill = provider.bills[index];
          return BillCard(
            bill: bill,
            onDelete: () => _deleteBill(bill),
            onPay: () => _onPaymentSuccess(bill),
            onPayWithBill: (b) => _onPaymentSuccess(b),
          );
        },
      ),
    );
  }
}
