import 'package:flutter/material.dart';
import '../../../models/bill.dart';
import 'payment_modal.dart';

class BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onDelete;
  final VoidCallback? onPay;
  final Function(Bill)? onPayWithBill;

  const BillCard({
    super.key,
    required this.bill,
    this.onDelete,
    this.onPay,
    this.onPayWithBill,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isVerySmall = size.width < 320;

    return Dismissible(
      key: ValueKey(bill.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(isSmall),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: EdgeInsets.only(bottom: isSmall ? 12 : 16),
        elevation: isSmall ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isSmall, isVerySmall),
              SizedBox(height: isSmall ? 10 : 12),
              _buildCustomerInfo(isSmall),
              SizedBox(height: isSmall ? 10 : 12),
              const Divider(height: 1),
              SizedBox(height: isSmall ? 6 : 8),
              _buildItemsSection(isSmall),
              SizedBox(height: isSmall ? 10 : 12),
              const Divider(height: 1),
              SizedBox(height: isSmall ? 6 : 8),
              _buildTotalSection(isSmall),
              SizedBox(height: isSmall ? 10 : 12),
              _buildFooter(context, isSmall, isVerySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(bool isSmall) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: isSmall ? 16 : 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, color: Colors.white, size: isSmall ? 24 : 32),
          SizedBox(height: isSmall ? 2 : 4),
          Text(
            'DELETE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isSmall ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final isSmall = MediaQuery.of(context).size.width < 360;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red.shade400),
                SizedBox(width: isSmall ? 8 : 12),
                Expanded(
                  child: Text(
                    'Delete Bill?',
                    style: TextStyle(fontSize: isSmall ? 18 : 20),
                  ),
                ),
              ],
            ),
            content: Text(
              'Delete ${bill.billNumber}?\nThis cannot be undone.',
              style: TextStyle(fontSize: isSmall ? 14 : null),
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

  Widget _buildHeader(bool isSmall, bool isVerySmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.receipt, size: isSmall ? 18 : 20),
              SizedBox(width: isSmall ? 6 : 8),
              Expanded(
                child: Text(
                  bill.billNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 14 : 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(isSmall),
      ],
    );
  }

  Widget _buildStatusBadge(bool isSmall) {
    final color = _getStatusColor(bill.status);
    final label = isSmall ? _getShortStatus(bill.status) : bill.statusDisplay;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: isSmall ? 10 : 12,
        ),
      ),
    );
  }

  String _getShortStatus(BillStatus status) {
    switch (status) {
      case BillStatus.paid:
        return 'Paid';
      case BillStatus.partiallyPaid:
        return 'Partial';
      case BillStatus.pending:
        return 'Pending';
      case BillStatus.cancelled:
        return 'Cancelled';
    }
  }

  Widget _buildCustomerInfo(bool isSmall) {
    final name = bill.customer.name;
    final number = bill.customer.number;
    final display = number != null && !isSmall ? '$name ($number)' : name;

    return Text(
      'Customer: $display',
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: isSmall ? 13 : 14,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildItemsSection(bool isSmall) {
    // Show max 3 items on small screens, expand to see more
    final displayItems = isSmall && bill.billedItems.length > 3
        ? bill.billedItems.take(3).toList()
        : bill.billedItems;
    final hasMore = isSmall && bill.billedItems.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isSmall ? 11 : 12,
          ),
        ),
        SizedBox(height: isSmall ? 6 : 8),
        ...displayItems.map((item) => _buildItemRow(item, isSmall)),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${bill.billedItems.length - 3} more',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemRow(BilledItem item, bool isSmall) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmall ? 3 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item.menuItemName} × ${item.quantity}',
              style: TextStyle(fontSize: isSmall ? 13 : 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isSmall ? 6 : 8),
          Text(
            'Rs. ${item.subtotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isSmall ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(bool isSmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isSmall ? 14 : 16,
          ),
        ),
        Text(
          'Rs. ${bill.totalAmount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isSmall ? 16 : 18,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isSmall, bool isVerySmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By: ${bill.createdBy}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: isSmall ? 11 : 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (bill.createdAt != null)
                Text(
                  _formatTimeAgo(bill.createdAt!),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: isSmall ? 11 : 12,
                  ),
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
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 24,
                vertical: isSmall ? 8 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isVerySmall ? 'Pay' : 'Pay Now',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 12 : 14,
              ),
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
