class Order {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerId;
  final String createdBy;
  final String? createdByEmail;
  final String status; // notReceived, received, cancelled
  final String billingStatus; // unbilled, partiallyBilled, fullyBilled
  final List<OrderItem> orderedItems;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerId,
    required this.createdBy,
    this.createdByEmail,
    required this.status,
    required this.billingStatus,
    required this.orderedItems,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'],
      orderNumber: json['orderNumber'],
      customerName: json['customer']?['name'] ?? 'Unknown',
      customerId: json['customer']?['_id'],
      createdBy: json['createdBy']?['name'] ?? 'Unknown',
      createdByEmail: json['createdBy']?['email'],
      status: json['status'] ?? 'notReceived',
      billingStatus: json['billingStatus'] ?? 'unbilled',
      orderedItems:
          (json['orderedItems'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double priceAtOrder;
  final int billedQuantity;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.priceAtOrder,
    required this.billedQuantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItem']?['_id'] ?? '',
      name: json['menuItem']?['name'] ?? 'Unknown Item',
      quantity: json['quantity'] ?? 1,
      priceAtOrder: (json['priceAtOrder'] as num?)?.toDouble() ?? 0.0,
      billedQuantity: json['billedQuantity'] ?? 0,
    );
  }

  double get total => priceAtOrder * quantity;
}
