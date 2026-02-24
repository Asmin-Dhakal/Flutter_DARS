import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/order.dart' as models;
import 'notification_service.dart';

/// Service for managing orders in Firestore and handling real-time notifications
///
/// This service:
/// - Saves orders to Firestore after API calls
/// - Listens for new orders created by any staff member
/// - Listens for order status changes (received, completed)
/// - Shows local notifications for these events
class FirestoreOrderService {
  // Singleton pattern
  static final FirestoreOrderService _instance =
      FirestoreOrderService._internal();
  factory FirestoreOrderService() => _instance;
  FirestoreOrderService._internal();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference for orders
  CollectionReference get _ordersCollection => _firestore.collection('orders');

  // Stream subscription for order listener
  StreamSubscription<QuerySnapshot>? _orderSubscription;

  // Track orders we've already seen to avoid duplicate notifications
  final Set<String> _seenOrderIds = {};

  // Track order statuses to detect changes
  final Map<String, String> _orderStatusCache = {};

  // Track if we've received the initial snapshot (to avoid notifications for existing orders)
  bool _initialSnapshotReceived = false;

  // Notification service
  final NotificationServices _notificationService = NotificationServices();

  // Lazy getter for local notifications
  FlutterLocalNotificationsPlugin get _localNotifications =>
      _notificationService.flutterLocalNotificationsPlugin;

  bool _isListening = false;

  /// Save an order to Firestore
  ///
  /// Call this AFTER successfully creating an order via REST API
  /// This keeps Firestore in sync with your backend
  Future<void> saveOrderToFirestore(models.Order order) async {
    try {
      await _ordersCollection.doc(order.id).set({
        'id': order.id,
        'orderNumber': order.orderNumber,
        'customerName': order.customerName,
        'customerId': order.customerId,
        'createdBy': order.createdBy,
        'createdByEmail': order.createdByEmail,
        'status': order.status.toLowerCase(),
        'billingStatus': order.billingStatus.toLowerCase(),
        'totalAmount': order.totalAmount,
        'notes': order.notes,
        'createdAt': order.createdAt.toIso8601String(),
        'updatedAt': order.updatedAt?.toIso8601String(),
        'isDeleted': order.isDeleted,
        // Simplified items for Firestore
        'itemCount': order.orderedItems.length,
      }, SetOptions(merge: true));

      debugPrint('✅ Order ${order.orderNumber} saved to Firestore');
    } catch (e) {
      debugPrint('⚠️ Failed to save order to Firestore: $e');
      // Don't throw error - Firestore sync failure shouldn't break order creation
    }
  }

  /// Update order status in Firestore
  ///
  /// Call this when order status changes (received, completed, cancelled)
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': status.toLowerCase(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Order $orderId status updated to $status in Firestore');
    } catch (e) {
      debugPrint('⚠️ Failed to update order status in Firestore: $e');
    }
  }

  /// Start listening for order changes
  ///
  /// This sets up a real-time listener that detects:
  /// - New orders created by any staff member
  /// - Orders marked as received
  /// - Orders marked as completed
  void startListening() {
    if (_isListening) {
      debugPrint('Already listening to orders');
      return;
    }

    debugPrint('🔊 Starting Firestore order listener...');
    _isListening = true;

    // Listen to all orders, ordered by creation time
    _orderSubscription = _ordersCollection
        .orderBy('createdAt', descending: true)
        .limit(50) // Only monitor recent 50 orders
        .snapshots()
        .listen(
          (snapshot) {
            // Use a regular async method to handle the snapshot
            _handleOrderSnapshot(snapshot);
          },
          onError: (error) {
            debugPrint('❌ Firestore listener error: $error');
          },
        );
  }

  /// Stop listening for order changes
  ///
  /// Call this when user logs out
  void stopListening() {
    if (!_isListening) return;

    debugPrint('🔇 Stopping Firestore order listener...');
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _isListening = false;
  }

  /// Handle order snapshot changes from Firestore
  void _handleOrderSnapshot(QuerySnapshot snapshot) {
    // On first snapshot, just populate cache - don't show notifications
    if (!_initialSnapshotReceived) {
      _initialSnapshotReceived = true;
      debugPrint('📦 Loading initial orders from Firestore...');

      // Just populate cache with existing orders
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final orderId = data['id'] as String;
          final status = (data['status'] as String).toLowerCase();

          _seenOrderIds.add(orderId);
          _orderStatusCache[orderId] = status;
        }
      }
      debugPrint('✅ Initial orders loaded: ${_seenOrderIds.length} orders');
      return; // Don't show notifications on initial load
    }

    // After initial snapshot, process new changes
    for (var change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>;
      final orderId = data['id'] as String;
      final status = (data['status'] as String).toLowerCase();

      switch (change.type) {
        case DocumentChangeType.added:
          // New order detected (after initial load)
          if (!_seenOrderIds.contains(orderId)) {
            _seenOrderIds.add(orderId);
            _orderStatusCache[orderId] = status;

            // Show notification for truly new orders (fire and forget)
            _showNewOrderNotification(data);
          }
          break;

        case DocumentChangeType.modified:
          // Order status changed
          final cachedStatus = _orderStatusCache[orderId];

          if (cachedStatus != null && cachedStatus != status) {
            // Status changed - check what changed to
            if (status == 'received' && cachedStatus == 'notreceived') {
              _showOrderReceivedNotification(data);
            } else if (status == 'completed') {
              _showOrderCompletedNotification(data);
            } else if (status == 'cancelled') {
              _showOrderCancelledNotification(data);
            }

            // Update cache
            _orderStatusCache[orderId] = status;
          }
          break;

        case DocumentChangeType.removed:
          // Order deleted - remove from cache
          _seenOrderIds.remove(orderId);
          _orderStatusCache.remove(orderId);
          break;
      }
    }
  }

  /// Show notification when a new order is created
  void _showNewOrderNotification(Map<String, dynamic> data) {
    final orderNumber = data['orderNumber'] as String;
    final customerName = data['customerName'] as String;
    final itemCount = data['itemCount'] as int? ?? 0;
    final orderId = data['id'] as String;

    debugPrint('🆕 New order notification: $orderNumber');

    // Pass both orderId and orderNumber in payload as JSON
    final payload = '$orderId|$orderNumber';

    // Fire and forget - show notification asynchronously
    _showLocalNotification(
      id: orderNumber.hashCode,
      title: '🆕 New Order Created',
      body: 'Order $orderNumber for $customerName - $itemCount items',
      payload: payload,
    );
  }

  /// Show notification when an order is received
  void _showOrderReceivedNotification(Map<String, dynamic> data) {
    final orderNumber = data['orderNumber'] as String;
    final orderId = data['id'] as String;

    debugPrint('📥 Order received notification: $orderNumber');

    final payload = '$orderId|$orderNumber';

    // Fire and forget - show notification asynchronously
    _showLocalNotification(
      id: orderNumber.hashCode + 1,
      title: '📥 Order Received',
      body: 'Order $orderNumber has been received',
      payload: payload,
    );
  }

  /// Show notification when an order is completed
  void _showOrderCompletedNotification(Map<String, dynamic> data) {
    final orderNumber = data['orderNumber'] as String;
    final customerName = data['customerName'] as String;
    final orderId = data['id'] as String;

    debugPrint('✅ Order completed notification: $orderNumber');

    final payload = '$orderId|$orderNumber';

    // Fire and forget - show notification asynchronously
    _showLocalNotification(
      id: orderNumber.hashCode + 2,
      title: '✅ Order Completed',
      body: 'Order $orderNumber for $customerName is now complete!',
      payload: payload,
    );
  }

  /// Show notification when an order is cancelled
  void _showOrderCancelledNotification(Map<String, dynamic> data) {
    final orderNumber = data['orderNumber'] as String;
    final customerName = data['customerName'] as String;
    final orderId = data['id'] as String;

    debugPrint('❌ Order cancelled notification: $orderNumber');

    final payload = '$orderId|$orderNumber';

    // Fire and forget - show notification asynchronously
    _showLocalNotification(
      id: orderNumber.hashCode + 3,
      title: '❌ Order Cancelled',
      body: 'Order $orderNumber for $customerName has been cancelled',
      payload: payload,
    );
  }

  /// Generic method to show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'order_updates_channel',
          'Order Updates',
          channelDescription:
              'Notifications for order creation and status changes',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/launcher_icon',
          fullScreenIntent: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: notificationDetails,
      );
      debugPrint('✅ Notification shown successfully (ID: $id)');
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  /// Clear cache and reset state
  ///
  /// Call this when user logs out
  void clearCache() {
    _seenOrderIds.clear();
    _orderStatusCache.clear();
    _initialSnapshotReceived = false;
    debugPrint('🗑️ Firestore order cache cleared');
  }

  /// Check if listener is active
  bool get isListening => _isListening;
}
