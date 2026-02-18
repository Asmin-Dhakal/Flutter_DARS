class MenuItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? itemType; // category/type from backend
  final bool? isAvailable;
  final bool? isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.itemType,
    this.isAvailable,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      itemType: json['itemType'],
      isAvailable: json['isAvailable'],
      isDeleted: json['isDeleted'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'itemType': itemType,
      'isAvailable': isAvailable,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
