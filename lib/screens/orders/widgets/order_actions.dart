import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/modern_dialog.dart';
import '../../../core/widgets/modern_snackbar.dart';
import '../../../providers/order_provider.dart';
import '../../../services/order_service.dart';
import '../../../services/firestore_order_service.dart';
import '../../../core/widgets/skeleton.dart';

/// Modern, modular order actions following Material 3 design
/// Optimized for low-end devices with minimal animations
class OrderActions {
  final BuildContext context;
  bool _isProcessing = false;

  OrderActions(this.context);

  // Action configurations using your theme colors
  static final _actionConfigs = {
    'receive': _ActionConfig(
      title: 'Receive Order',
      icon: Icons.check_circle_outline,
      color: AppColors.success,
      message: 'Mark this order as received?',
      confirmText: 'Confirm Receive',
      successMessage: 'Order marked as received',
    ),
    'complete': _ActionConfig(
      title: 'Complete Order',
      icon: Icons.done_all,
      color: AppColors.info,
      message: 'Mark this order as completed?',
      confirmText: 'Complete Order',
      successMessage: 'Order completed',
    ),
    'cancel': _ActionConfig(
      title: 'Cancel Order',
      icon: Icons.cancel_outlined,
      color: AppColors.error,
      message: 'Are you sure you want to cancel this order?',
      confirmText: 'Yes, Cancel',
      successMessage: 'Order cancelled',
      warning: 'This action cannot be undone.',
      isDestructive: true,
    ),
    'delete': _ActionConfig(
      title: 'Delete Order',
      icon: Icons.delete_outline,
      color: AppColors.error,
      message: 'Delete order {orderNumber}?',
      confirmText: 'Delete',
      successMessage: 'Order deleted',
      warning: 'This action cannot be undone.',
      isDestructive: true,
    ),
  };

  Future<void> receive(String orderId) => _execute(
    actionKey: 'receive',
    orderId: orderId,
    status: 'received',
    apiCall: () =>
        OrderService.updateOrderStatus(orderId: orderId, status: 'received'),
  );

  Future<void> complete(String orderId) => _execute(
    actionKey: 'complete',
    orderId: orderId,
    status: 'completed',
    apiCall: () =>
        OrderService.updateOrderStatus(orderId: orderId, status: 'completed'),
  );

  Future<void> cancel(String orderId) => _execute(
    actionKey: 'cancel',
    orderId: orderId,
    status: 'cancelled',
    apiCall: () =>
        OrderService.updateOrderStatus(orderId: orderId, status: 'cancelled'),
  );

  Future<void> delete(String orderId, String orderNumber) => _execute(
    actionKey: 'delete',
    orderId: orderId,
    orderNumber: orderNumber,
    apiCall: () => OrderService.deleteOrder(orderId),
  );

  /// Core execution flow with loading state and error handling
  Future<void> _execute({
    required String actionKey,
    required String orderId,
    String? orderNumber,
    String? status,
    required Future<dynamic> Function() apiCall,
  }) async {
    if (_isProcessing) return;

    final config = _actionConfigs[actionKey]!;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (_) => ModernConfirmDialog(
        title: config.title,
        icon: config.icon,
        iconColor: config.color,
        message: orderNumber != null
            ? config.message.replaceAll('{orderNumber}', orderNumber)
            : config.message,
        confirmText: config.confirmText,
        confirmColor: config.color,
        warning: config.warning,
        isDestructive: config.isDestructive,
      ),
    );

    if (confirmed != true) return;

    _isProcessing = true;
    _showLoading();

    try {
      await apiCall();

      // Update Firestore for real-time notifications
      if (status != null) {
        await FirestoreOrderService().updateOrderStatus(orderId, status);
      }

      if (!context.mounted) return;
      _hideLoading();

      if (!context.mounted) return;
      ModernSnackBar.success(context, config.successMessage);

      // Refresh provider
      context.read<OrderProvider>().loadOrders();
    } catch (e) {
      if (!context.mounted) return;
      _hideLoading();

      if (!context.mounted) return;
      ModernSnackBar.error(context, 'Error: ${e.toString()}');
    } finally {
      _isProcessing = false;
    }
  }

  /// Lightweight loading indicator optimized for low-end devices
  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.gray900.withOpacity(0.3),
      builder: (_) => const Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(48)),
          ),
        ),
      ),
    );
  }

  void _hideLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Configuration for each action type
class _ActionConfig {
  final String title;
  final IconData icon;
  final Color color;
  final String message;
  final String confirmText;
  final String successMessage;
  final String? warning;
  final bool isDestructive;

  const _ActionConfig({
    required this.title,
    required this.icon,
    required this.color,
    required this.message,
    required this.confirmText,
    required this.successMessage,
    this.warning,
    this.isDestructive = false,
  });
}
