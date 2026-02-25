/// Game bill model for tennis and snooker billing
class GameBill {
  final String id;
  final String billNumber;
  final String gameType; // 'table-tennis' or 'snooker-pool'
  final String session; // Session ID
  final String sessionModel; // 'TennisSession' or 'SnookerSession'
  final int tableNumber;
  final String customerName;
  final String paymentStatus; // 'pending', 'paid'

  // Tennis specific fields
  final int? durationMinutes;
  final double? pricePerMinute;

  // Snooker specific fields
  final int? gameCount;
  final double? pricePerGame;

  // Common billing fields
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final String createdById;
  final String createdByName;
  final String createdByEmail;
  final String? notes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final String? paidOnId;
  final String? paidOnName;

  GameBill({
    required this.id,
    required this.billNumber,
    required this.gameType,
    required this.session,
    required this.sessionModel,
    required this.tableNumber,
    required this.customerName,
    required this.paymentStatus,
    this.durationMinutes,
    this.pricePerMinute,
    this.gameCount,
    this.pricePerGame,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
    required this.createdById,
    required this.createdByName,
    required this.createdByEmail,
    this.notes,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.paidOnId,
    this.paidOnName,
  });

  /// Factory constructor to create GameBill from JSON
  factory GameBill.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] is Map<String, dynamic>
        ? json['createdBy']
        : {'_id': json['createdBy'], 'name': '', 'email': ''};

    final paidOn = json['paidOn'] is Map<String, dynamic>
        ? json['paidOn']
        : null;

    return GameBill(
      id: json['_id'] ?? '',
      billNumber: json['billNumber'] ?? '',
      gameType: json['gameType'] ?? '',
      session: json['session'] ?? '',
      sessionModel: json['sessionModel'] ?? '',
      tableNumber: json['tableNumber'] ?? 0,
      customerName: json['customerName'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      durationMinutes: json['durationMinutes'],
      pricePerMinute: json['pricePerMinute'] != null
          ? (json['pricePerMinute'] as num).toDouble()
          : null,
      gameCount: json['gameCount'],
      pricePerGame: json['pricePerGame'] != null
          ? (json['pricePerGame'] as num).toDouble()
          : null,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      createdById: createdBy['_id'] ?? '',
      createdByName: createdBy['name'] ?? '',
      createdByEmail: createdBy['email'] ?? '',
      notes: json['notes'],
      isDeleted: json['isDeleted'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      paidOnId: paidOn?['_id'],
      paidOnName: paidOn?['paymentName'],
    );
  }

  /// Convert GameBill to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'billNumber': billNumber,
      'gameType': gameType,
      'session': session,
      'sessionModel': sessionModel,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'paymentStatus': paymentStatus,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (pricePerMinute != null) 'pricePerMinute': pricePerMinute,
      if (gameCount != null) 'gameCount': gameCount,
      if (pricePerGame != null) 'pricePerGame': pricePerGame,
      'totalAmount': totalAmount,
      'discount': discount,
      'finalAmount': finalAmount,
      'createdBy': {
        '_id': createdById,
        'name': createdByName,
        'email': createdByEmail,
      },
      'notes': notes,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      if (paidOnId != null && paidOnName != null)
        'paidOn': {'_id': paidOnId, 'paymentName': paidOnName},
    };
  }

  /// Get game type display name
  String get gameTypeDisplay {
    if (gameType == 'table-tennis') return 'Table Tennis';
    if (gameType == 'snooker-pool') return 'Snooker & Pool';
    return gameType;
  }

  /// Get payment status display text
  String get paymentStatusText {
    switch (paymentStatus) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      default:
        return paymentStatus;
    }
  }

  /// Check if bill is paid
  bool get isPaid => paymentStatus == 'paid';

  /// Check if bill is pending
  bool get isPending => paymentStatus == 'pending';

  /// Get duration display (for tennis)
  String get durationDisplay {
    if (durationMinutes == null) return '';
    return '${durationMinutes}m';
  }

  /// Get game count display (for snooker)
  String get gameCountDisplay {
    if (gameCount == null) return '';
    return '$gameCount game${gameCount! > 1 ? 's' : ''}';
  }

  /// Copy with method for immutability
  GameBill copyWith({
    String? id,
    String? billNumber,
    String? gameType,
    String? session,
    String? sessionModel,
    int? tableNumber,
    String? customerName,
    String? paymentStatus,
    int? durationMinutes,
    double? pricePerMinute,
    int? gameCount,
    double? pricePerGame,
    double? totalAmount,
    double? discount,
    double? finalAmount,
    String? createdById,
    String? createdByName,
    String? createdByEmail,
    String? notes,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    String? paidOnId,
    String? paidOnName,
  }) {
    return GameBill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      gameType: gameType ?? this.gameType,
      session: session ?? this.session,
      sessionModel: sessionModel ?? this.sessionModel,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      pricePerMinute: pricePerMinute ?? this.pricePerMinute,
      gameCount: gameCount ?? this.gameCount,
      pricePerGame: pricePerGame ?? this.pricePerGame,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      paidOnId: paidOnId ?? this.paidOnId,
      paidOnName: paidOnName ?? this.paidOnName,
    );
  }
}
