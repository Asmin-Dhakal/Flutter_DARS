class PaymentMethod {
  final String id;
  final String paymentName;
  final String paymentDetails;
  final String? imageUrl;
  final AdminInfo admin;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethod({
    required this.id,
    required this.paymentName,
    required this.paymentDetails,
    this.imageUrl,
    required this.admin,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      paymentName: json['paymentName']?.toString() ?? '',
      paymentDetails: json['paymentDetails']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      admin: json['adminId'] is Map<String, dynamic>
          ? AdminInfo.fromJson(json['adminId'])
          : AdminInfo(id: '', name: '', email: ''),
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  bool get isCash => paymentName.toLowerCase().contains('cash');
  bool get isEsewa => paymentName.toLowerCase().contains('esewa');

  String get displayName {
    final adminName = admin.name.isNotEmpty ? '(${admin.name})' : '';
    return '$paymentName $adminName'.trim();
  }
}

class AdminInfo {
  final String id;
  final String name;
  final String email;

  AdminInfo({required this.id, required this.name, required this.email});

  factory AdminInfo.fromJson(Map<String, dynamic> json) {
    return AdminInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}
