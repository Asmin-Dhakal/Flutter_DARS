import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import '../../../services/order_service.dart';

class OrderActions {
  final BuildContext context;
  bool _isProcessing = false;

  OrderActions(this.context);

  Future<void> receive(String orderId) async {
    await _showConfirmDialog(
      title: 'Receive Order',
      icon: Icons.check_circle,
      iconColor: Colors.green,
      message: 'Mark this order as received?',
      confirmText: 'Confirm Receive',
      confirmColor: Colors.green,
      action: () =>
          OrderService.updateOrderStatus(orderId: orderId, status: 'received'),
      successMessage: 'Order marked as received',
      successColor: Colors.green,
    );
  }

  Future<void> complete(String orderId) async {
    await _showConfirmDialog(
      title: 'Complete Order',
      icon: Icons.done_all,
      iconColor: Colors.blue,
      message: 'Mark this order as completed?',
      confirmText: 'Complete Order',
      confirmColor: Colors.blue,
      action: () =>
          OrderService.updateOrderStatus(orderId: orderId, status: 'completed'),
      successMessage: 'Order completed',
      successColor: Colors.blue,
    );
  }

  Future<void> cancel(String orderId) async {
    await _showConfirmDialog(
      title: 'Cancel Order',
      icon: Icons.cancel,
      iconColor: Colors.red,
      message: 'Are you sure you want to cancel this order?',
      confirmText: 'Yes, Cancel',
      confirmColor: Colors.red,
      warning: 'This action cannot be undone.',
      action: () =>
          OrderService.updateOrderStatus(orderId: orderId, status: 'cancelled'),
      successMessage: 'Order cancelled',
      successColor: Colors.red,
    );
  }

  Future<void> delete(String orderId, String orderNumber) async {
    await _showConfirmDialog(
      title: 'Delete Order',
      icon: Icons.delete_forever,
      iconColor: Colors.red,
      message: 'Delete order $orderNumber?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      warning: 'This action cannot be undone.',
      action: () => OrderService.deleteOrder(orderId),
      successMessage: 'Order deleted',
      successColor: Colors.green,
    );
  }

  Future<void> _showConfirmDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String message,
    required String confirmText,
    required MaterialColor confirmColor,
    String? warning,
    required Future<dynamic> Function() action,
    required String successMessage,
    required MaterialColor successColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (warning != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    if (confirmed != true || _isProcessing) return;

    _isProcessing = true;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await action();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Hide loading

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(successMessage),
            ],
          ),
          backgroundColor: successColor.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      context.read<OrderProvider>().loadOrders();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Hide loading

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      _isProcessing = false;
    }
  }
}
