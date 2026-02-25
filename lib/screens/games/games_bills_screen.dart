import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/modern_snackbar.dart';
import '../../services/game_service.dart';
import '../../models/game_bill.dart';

class GamesBillsScreen extends StatefulWidget {
  const GamesBillsScreen({super.key});

  @override
  State<GamesBillsScreen> createState() => _GamesBillsScreenState();
}

class _GamesBillsScreenState extends State<GamesBillsScreen> {
  List<GameBill> _bills = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'all'; // 'all', 'pending', 'paid'

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await GameService.getAllGameBills();

      if (mounted) {
        setState(() {
          _bills = response.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<GameBill> get _filteredBills {
    if (_filterStatus == 'all') return _bills;
    if (_filterStatus == 'pending')
      return _bills.where((b) => b.isPending).toList();
    return _bills.where((b) => b.isPaid).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Bills'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBills),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _bills.isEmpty
          ? _buildEmptyState()
          : _buildBillsList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppTokens.space3),
          Text(
            'Error loading bills',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
          const SizedBox(height: AppTokens.space4),
          ElevatedButton(onPressed: _loadBills, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 48, color: AppColors.gray400),
          const SizedBox(height: AppTokens.space3),
          Text(
            'No game bills yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Game bills will appear here once sessions are billed',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList() {
    final filteredBills = _filteredBills;

    return Column(
      children: [
        // Filter Tabs
        Padding(
          padding: const EdgeInsets.all(AppTokens.space3),
          child: Row(
            children: [
              _buildFilterChip('all', 'All (${_bills.length})'),
              const SizedBox(width: AppTokens.space2),
              _buildFilterChip(
                'pending',
                'Pending (${_bills.where((b) => b.isPending).length})',
              ),
              const SizedBox(width: AppTokens.space2),
              _buildFilterChip(
                'paid',
                'Paid (${_bills.where((b) => b.isPaid).length})',
              ),
            ],
          ),
        ),

        // Bills List
        Expanded(
          child: filteredBills.isEmpty
              ? Center(
                  child: Text(
                    'No bills with status: $_filterStatus',
                    style: TextStyle(fontSize: 13, color: AppColors.gray600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space3,
                    vertical: AppTokens.space2,
                  ),
                  itemCount: filteredBills.length,
                  itemBuilder: (context, index) {
                    final bill = filteredBills[index];
                    return _BillCard(bill: bill);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.onPrimary : AppColors.gray800,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final GameBill bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(
          color: bill.isPaid ? AppColors.success : AppColors.warning,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Bill Number and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill ${bill.billNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray800,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space1),
                      Text(
                        bill.gameTypeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space2,
                    vertical: AppTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: bill.isPaid
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: Text(
                    bill.paymentStatusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: bill.isPaid
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTokens.space3),

            // Bill Details
            _buildDetailRow('Customer', bill.customerName),
            const SizedBox(height: AppTokens.space2),
            _buildDetailRow('Table', '${bill.tableNumber}'),
            const SizedBox(height: AppTokens.space2),

            // Display games or duration based on game type
            if (bill.gameType == 'table-tennis')
              _buildDetailRow('Duration', bill.durationDisplay)
            else
              _buildDetailRow('Games', bill.gameCountDisplay),

            const SizedBox(height: AppTokens.space2),

            // Amount
            _buildDetailRow(
              'Final Amount',
              'Rs. ${bill.finalAmount?.toStringAsFixed(2) ?? '0.00'}',
              valueColor: AppColors.primary,
              valueFontWeight: FontWeight.w600,
            ),

            // Notes (if available)
            if (bill.notes != null && bill.notes!.isNotEmpty) ...[
              const SizedBox(height: AppTokens.space2),
              Text(
                'Notes: ${bill.notes}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray600,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.gray600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: valueFontWeight ?? FontWeight.w500,
            color: valueColor ?? AppColors.gray800,
          ),
        ),
      ],
    );
  }
}
