import 'customer.dart';

enum BillStatus { pending, paid, partiallyPaid, cancelled }

class BilledItem {
  final String? id;
  final String orderId;
  final String orderNumber;
  final String menuItemId;
  final String menuItemName;
  final String menuItemType;
  final double menuItemPrice;
  final int quantity;
  final double priceAtOrder;
  final double subtotal;

  BilledItem({
    this.id,
    required this.orderId,
    required this.orderNumber,
    required this.menuItemId,
    required this.menuItemName,
    required this.menuItemType,
    required this.menuItemPrice,
    required this.quantity,
    required this.priceAtOrder,
    required this.subtotal,
  });

  factory BilledItem.fromJson(Map<String, dynamic> json) {
    // Parse nested order
    final orderData = json['order'] as Map<String, dynamic>?;
    // Parse nested menuItem
    final menuItemData = json['menuItem'] as Map<String, dynamic>?;

    return BilledItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      orderId:
          orderData?['_id']?.toString() ?? orderData?['id']?.toString() ?? '',
      orderNumber: orderData?['orderNumber']?.toString() ?? '',
      menuItemId:
          menuItemData?['_id']?.toString() ??
          menuItemData?['id']?.toString() ??
          '',
      menuItemName: menuItemData?['name']?.toString() ?? 'Unknown Item',
      menuItemType: menuItemData?['itemType']?.toString() ?? '',
      menuItemPrice: (menuItemData?['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      priceAtOrder: (json['priceAtOrder'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class Bill {
  final String? id;
  final String billNumber;
  final Customer customer;
  final List<BilledItem> billedItems;
  final double totalAmount;
  final double? paidAmount;
  final String? paymentStatus;
  final String? notes;
  final String createdBy; // This will store the name
  final String? createdById; // Store ID separately if needed
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Bill({
    this.id,
    required this.billNumber,
    required this.customer,
    required this.billedItems,
    required this.totalAmount,
    this.paidAmount,
    this.paymentStatus,
    this.notes,
    required this.createdBy,
    this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    // Parse createdBy - can be object or string
    String creatorName = 'Unknown';
    String? creatorId;

    if (json['createdBy'] is Map<String, dynamic>) {
      creatorName = json['createdBy']['name']?.toString() ?? 'Unknown';
      creatorId = json['createdBy']['_id']?.toString();
    } else if (json['createdBy'] is String) {
      creatorName = json['createdBy'];
    }

    return Bill(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      billNumber: json['billNumber']?.toString() ?? '',
      customer: json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'])
          : Customer(id: '', name: 'Unknown'),
      billedItems:
          (json['billedItems'] as List<dynamic>?)
              ?.map((e) => BilledItem.fromJson(e))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: json['paidAmount'] != null
          ? (json['paidAmount']).toDouble()
          : null,
      paymentStatus: json['paymentStatus']?.toString(),
      notes: json['notes']?.toString(),
      createdBy: creatorName,
      createdById: creatorId,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  String get statusDisplay {
    final status = paymentStatus?.toLowerCase() ?? 'pending';
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'partially_paid':
      case 'partiallypaid':
        return 'Partially Paid';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  BillStatus get status {
    final status = paymentStatus?.toLowerCase() ?? 'pending';
    switch (status) {
      case 'paid':
        return BillStatus.paid;
      case 'partially_paid':
      case 'partiallypaid':
        return BillStatus.partiallyPaid;
      case 'cancelled':
        return BillStatus.cancelled;
      default:
        return BillStatus.pending;
    }
  }
}

class UnbilledCustomer {
  final String id;
  final String name;
  final String? gender;
  final int orderCount;
  final double totalUnbilledAmount;
  final List<UnbilledOrder> orders;

  UnbilledCustomer({
    required this.id,
    required this.name,
    this.gender,
    required this.orderCount,
    required this.totalUnbilledAmount,
    required this.orders,
  });

  factory UnbilledCustomer.fromJson(Map<String, dynamic> json) {
    final customerData = json['customer'] as Map<String, dynamic>?;

    return UnbilledCustomer(
      id:
          customerData?['_id']?.toString() ??
          customerData?['id']?.toString() ??
          '',
      name: customerData?['name']?.toString() ?? 'Unknown',
      gender: customerData?['gender']?.toString(),
      orderCount: json['orderCount'] ?? 0,
      totalUnbilledAmount: (json['totalUnbilledAmount'] ?? 0).toDouble(),
      orders:
          (json['orders'] as List<dynamic>?)
              ?.map((e) => UnbilledOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // FIXED: Count only items that have remaining unbilled quantity
  int get totalItemCount {
    int count = 0;
    for (final order in orders) {
      for (final item in order.orderedItems) {
        // Only count if there's remaining quantity to bill
        if (item.quantity > item.billedQuantity) {
          count++;
        }
      }
    }
    return count;
  }
}

class UnbilledOrder {
  final String id;
  final String orderNumber;
  final double totalAmount;
  final double unbilledAmount;
  final String billingStatus;
  final String status;
  final DateTime createdAt;
  final List<OrderedItem> orderedItems;

  UnbilledOrder({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.unbilledAmount,
    required this.billingStatus,
    required this.status,
    required this.createdAt,
    required this.orderedItems,
  });

  factory UnbilledOrder.fromJson(Map<String, dynamic> json) {
    return UnbilledOrder(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      unbilledAmount: (json['unbilledAmount'] ?? 0).toDouble(),
      billingStatus: json['billingStatus']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      orderedItems:
          (json['orderedItems'] as List<dynamic>?)
              ?.map((e) => OrderedItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderedItem {
  final String menuItemId;
  final int quantity;
  final double priceAtOrder;
  final int billedQuantity;
  final String? id;

  OrderedItem({
    required this.menuItemId,
    required this.quantity,
    required this.priceAtOrder,
    required this.billedQuantity,
    this.id,
  });

  factory OrderedItem.fromJson(Map<String, dynamic> json) {
    return OrderedItem(
      menuItemId: json['menuItem']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      priceAtOrder: (json['priceAtOrder'] ?? 0).toDouble(),
      billedQuantity: json['billedQuantity'] ?? 0,
      id: json['_id']?.toString() ?? json['id']?.toString(),
    );
  }

  // Helper to check if item has remaining quantity
  int get remainingQuantity => quantity - billedQuantity;
  bool get isFullyBilled => remainingQuantity <= 0;
}
// Add this to your existing bill.dart file

class MenuItem {
  final String id;
  final String name;
  final String itemType;
  final double price;
  final bool isDeleted;

  MenuItem({
    required this.id,
    required this.name,
    required this.itemType,
    required this.price,
    required this.isDeleted,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Item',
      itemType: json['itemType']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}

// Model for selectable bill item (for the UI)
class SelectableBillItem {
  final String orderId;
  final String orderNumber;
  final String menuItemId;
  String menuItemName;
  final double priceAtOrder;
  final int availableQuantity;
  int selectedQuantity;
  bool isSelected;
  final String customerId;
  final String customerName;

  SelectableBillItem({
    required this.orderId,
    required this.orderNumber,
    required this.menuItemId,
    this.menuItemName = 'Loading...',
    required this.priceAtOrder,
    required this.availableQuantity,
    this.selectedQuantity = 0,
    this.isSelected = false,
    required this.customerId,
    required this.customerName,
  });

  double get totalPrice => priceAtOrder * selectedQuantity;
}
