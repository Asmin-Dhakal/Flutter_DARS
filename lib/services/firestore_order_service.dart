import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/order.dart' as models;
import 'notification_service.dart';

/// Callback type for order updates from Firestore listener
typedef OnOrderUpdated = void Function(models.Order order, String changeType);

/// Service for managing orders in Firestore and handling real-time notifications
///
/// This service:
/// - Saves orders to Firestore after API calls
/// - Listens for new orders created by any staff member
/// - Listens for order status changes (received, completed)
/// - Shows local notifications for these events
/// - Notifies listeners of real-time order changes
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

  // Track item counts to detect when items are edited
  final Map<String, int> _orderItemCountCache = {};

  // Track deleted order IDs to avoid duplicate notifications
  final Set<String> _deletedOrderIds = {};

  // Track if we've received the initial snapshot (to avoid notifications for existing orders)
  bool _initialSnapshotReceived = false;

  // Notification service
  final NotificationServices _notificationService = NotificationServices();

  // Lazy getter for local notifications
  FlutterLocalNotificationsPlugin get _localNotifications =>
      _notificationService.flutterLocalNotificationsPlugin;

  bool _isListening = false;

  // Callback for order updates (for real-time UI sync)
  OnOrderUpdated? onOrderUpdated;

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
        // Store items as an array for sync across devices
        'orderedItems': order.orderedItems
            .map(
              (item) => {
                'menuItemId': item.menuItemId,
                'name': item.name,
                'quantity': item.quantity,
                'priceAtOrder': item.priceAtOrder,
                'billedQuantity': item.billedQuantity,
              },
            )
            .toList(),
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

  /// Mark an order as deleted (soft delete)
  ///
  /// This soft-deletes the order so it propagates to all devices
  /// The Firestore listener will detect the change and notify OrderProvider
  Future<void> markOrderAsDeleted(String orderId) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'isDeleted': true,
        'status': 'deleted',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Order $orderId marked as deleted in Firestore');
    } catch (e) {
      debugPrint('⚠️ Failed to mark order as deleted in Firestore: $e');
    }
  }

  /// Update order items in Firestore
  ///
  /// Call this when order items are edited so changes sync to other devices
  Future<void> updateOrderItems(
    String orderId,
    List<models.OrderItem> items,
    double totalAmount,
  ) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'orderedItems': items
            .map(
              (item) => {
                'menuItemId': item.menuItemId,
                'name': item.name,
                'quantity': item.quantity,
                'priceAtOrder': item.priceAtOrder,
                'billedQuantity': item.billedQuantity,
              },
            )
            .toList(),
        'totalAmount': totalAmount,
        'itemCount': items.length,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Order $orderId items updated in Firestore');
    } catch (e) {
      debugPrint('⚠️ Failed to update order items in Firestore: $e');
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
          final itemCount = data['itemCount'] as int? ?? 0;

          _seenOrderIds.add(orderId);
          _orderStatusCache[orderId] = status;
          _orderItemCountCache[orderId] = itemCount;
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
      final itemCount = data['itemCount'] as int? ?? 0;
      final isDeleted = data['isDeleted'] as bool? ?? false;

      switch (change.type) {
        case DocumentChangeType.added:
          // New order detected (after initial load)
          if (!_seenOrderIds.contains(orderId)) {
            _seenOrderIds.add(orderId);
            _orderStatusCache[orderId] = status;

            // Show notification for truly new orders (fire and forget)
            _showNewOrderNotification(data);

            // Notify OrderProvider of new order
            try {
              final order = _mapFirestoreDataToOrder(data);
              onOrderUpdated?.call(order, 'added');
            } catch (e) {
              debugPrint('⚠️ Failed to map order data: $e');
            }
          }
          break;

        case DocumentChangeType.modified:
          // Order modified - check for deletion or status change

          // Handle soft delete (isDeleted flag set to true)
          if (isDeleted && !_deletedOrderIds.contains(orderId)) {
            _deletedOrderIds.add(orderId);
            _seenOrderIds.remove(orderId);
            _orderStatusCache.remove(orderId);

            debugPrint('🔄 Order $orderId marked as deleted');

            // Show deletion notification (fire and forget)
            _showOrderDeletedNotification(data);

            // Notify OrderProvider to remove order
            onOrderUpdated?.call(
              models.Order(
                id: orderId,
                orderNumber: data['orderNumber'] as String? ?? '',
                customerName: data['customerName'] as String? ?? 'Unknown',
                createdBy: data['createdBy'] as String? ?? 'Unknown',
                status: 'deleted',
                billingStatus: data['billingStatus'] as String? ?? 'unbilled',
                orderedItems: [],
                totalAmount: 0,
                createdAt: DateTime.now(),
                isDeleted: true,
              ),
              'removed',
            );
            break;
          }

          // Skip if already deleted
          if (isDeleted) break;

          // Track item count changes (order was edited)
          final cachedItemCount = _orderItemCountCache[orderId];
          final itemCountChanged =
              cachedItemCount != null && cachedItemCount != itemCount;

          // Handle status changes
          final cachedStatus = _orderStatusCache[orderId];
          final statusChanged = cachedStatus != null && cachedStatus != status;

          if (statusChanged) {
            debugPrint(
              '🔄 Order $orderId status changed: $cachedStatus → $status',
            );

            // Status changed - show appropriate notification
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

          // Handle item changes (order was edited)
          if (itemCountChanged) {
            debugPrint(
              '🔄 Order $orderId items edited: $cachedItemCount → $itemCount items',
            );

            // Show edit notification (fire and forget)
            _showOrderEditedNotification(data);

            // Update item count cache
            _orderItemCountCache[orderId] = itemCount;
          }

          // Notify OrderProvider of any changes (status or items)
          if (statusChanged || itemCountChanged) {
            try {
              final order = _mapFirestoreDataToOrder(data);
              onOrderUpdated?.call(order, 'modified');
            } catch (e) {
              debugPrint('⚠️ Failed to map order data: $e');
            }
          }
          break;

        case DocumentChangeType.removed:
          // Hard delete - order document completely removed from Firestore
          if (!_deletedOrderIds.contains(orderId)) {
            _deletedOrderIds.add(orderId);
            _seenOrderIds.remove(orderId);
            _orderStatusCache.remove(orderId);

            debugPrint('🔄 Order $orderId deleted from Firestore');

            // Show deletion notification
            final tempData = <String, dynamic>{
              'id': orderId,
              'orderNumber': data['orderNumber'] as String? ?? 'Unknown',
            };
            _showOrderDeletedNotification(tempData);

            // Notify OrderProvider of order removal
            onOrderUpdated?.call(
              models.Order(
                id: orderId,
                orderNumber: data['orderNumber'] as String? ?? '',
                customerName: data['customerName'] as String? ?? 'Unknown',
                createdBy: data['createdBy'] as String? ?? 'Unknown',
                status: 'deleted',
                billingStatus: data['billingStatus'] as String? ?? 'unbilled',
                orderedItems: [],
                totalAmount: 0,
                createdAt: DateTime.now(),
                isDeleted: true,
              ),
              'removed',
            );
          }
          break;
      }
    }
  }

  /// Map Firestore document data to Order model
  models.Order _mapFirestoreDataToOrder(Map<String, dynamic> data) {
    // Reconstruct items from Firestore data
    final List<models.OrderItem> items = [];
    final itemsData = data['orderedItems'] as List<dynamic>?;
    if (itemsData != null) {
      for (var itemData in itemsData) {
        final item = itemData as Map<String, dynamic>;
        items.add(
          models.OrderItem(
            menuItemId: item['menuItemId'] as String? ?? '',
            name: item['name'] as String? ?? 'Unknown Item',
            quantity: item['quantity'] as int? ?? 1,
            priceAtOrder: (item['priceAtOrder'] as num?)?.toDouble() ?? 0.0,
            billedQuantity: item['billedQuantity'] as int? ?? 0,
          ),
        );
      }
    }

    return models.Order(
      id: data['id'] as String? ?? '',
      orderNumber: data['orderNumber'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Unknown',
      customerId: data['customerId'] as String?,
      createdBy: data['createdBy'] as String? ?? 'Unknown',
      createdByEmail: data['createdByEmail'] as String?,
      status: data['status'] as String? ?? 'notreceived',
      billingStatus: data['billingStatus'] as String? ?? 'unbilled',
      orderedItems: items,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'] as String?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  /// Parse datetime from Firestore (ISO 8601 string)
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('⚠️ Failed to parse datetime: $value');
        return DateTime.now();
      }
    }
    return DateTime.now();
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

  /// Show notification when an order is deleted
  void _showOrderDeletedNotification(Map<String, dynamic> data) {
    final orderNumber = data['orderNumber'] as String;
    final orderId = data['id'] as String;

    debugPrint('🗑️ Order deleted notification: $orderNumber');

    final payload = '$orderId|$orderNumber';

    // Fire and forget - show notification asynchronously
    _showLocalNotification(
      id: orderNumber.hashCode + 4,
      title: '🗑️ Order Deleted',
      body: 'Order $orderNumber has been removed from the system',
      payload: payload,
    );
  }

  /// Show notification when an order is edited
  void _showOrderEditedNotification(Map<String, dynamic> data) {
    final orderNumber = data['orderNumber'] as String;
    final customerName = data['customerName'] as String;
    final orderId = data['id'] as String;
    final itemCount = data['itemCount'] as int? ?? 0;

    debugPrint('✏️ Order edited notification: $orderNumber');

    final payload = '$orderId|$orderNumber';

    // Fire and forget - show notification asynchronously
    _showLocalNotification(
      id: orderNumber.hashCode + 5,
      title: '✏️ Order Updated',
      body:
          'Order $orderNumber for $customerName has been edited ($itemCount items)',
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
