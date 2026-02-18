import 'package:flutter/material.dart';
import '../../../models/bill.dart';
import 'payment_modal.dart';

class BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onDelete;
  final VoidCallback? onPay;
  final Function(Bill)? onPayWithBill;

  const BillCard({
    Key? key,
    required this.bill,
    this.onDelete,
    this.onPay,
    this.onPayWithBill,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(bill.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildCustomerInfo(),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildItemsSection(),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildTotalSection(),
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, color: Colors.white, size: 32),
          SizedBox(height: 4),
          Text(
            'DELETE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red.shade400),
                const SizedBox(width: 12),
                const Text('Delete Bill?'),
              ],
            ),
            content: Text(
              'Are you sure you want to delete ${bill.billNumber}?\n\nThis action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.receipt, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bill.billNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor(bill.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        bill.statusDisplay,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Text(
      'Customer: ${bill.customer.name}${bill.customer.number != null ? ' (${bill.customer.number})' : ''}',
      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        ...bill.billedItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.menuItemName} × ${item.quantity}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Rs. ${item.subtotal.toStringAsFixed(0)}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        Text(
          'Rs. ${bill.totalAmount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Created by: ${bill.createdBy}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              if (bill.createdAt != null)
                Text(
                  _formatTimeAgo(bill.createdAt!),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
            ],
          ),
        ),
        if (bill.status != BillStatus.paid)
          ElevatedButton(
            onPressed: () => _showPaymentModal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565c0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Pay Now',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  void _showPaymentModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PaymentModal(bill: bill),
    ).then((result) {
      if (result == true) {
        onPay?.call();
        onPayWithBill?.call(bill);
      }
    });
  }

  Color _getStatusColor(BillStatus status) {
    switch (status) {
      case BillStatus.paid:
        return Colors.green;
      case BillStatus.partiallyPaid:
        return Colors.orange;
      case BillStatus.cancelled:
        return Colors.red;
      case BillStatus.pending:
        return Colors.blue;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
