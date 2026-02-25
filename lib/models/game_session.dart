/// Game session model
class GameSession {
  final String id;
  final int tableNumber;
  final String customerName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final double totalAmount;
  final String status; // 'active', 'paused', 'completed', 'billed'
  final int totalPausedMinutes;
  final String createdBy;
  final String? notes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameSession({
    required this.id,
    required this.tableNumber,
    required this.customerName,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.totalAmount = 0,
    this.status = 'active',
    this.totalPausedMinutes = 0,
    required this.createdBy,
    this.notes,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create GameSession from JSON
  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['_id'] ?? '',
      tableNumber: json['tableNumber'] ?? 0,
      customerName: json['customerName'] ?? '',
      startTime: DateTime.parse(
        json['startTime'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      durationMinutes: json['durationMinutes'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      totalPausedMinutes: json['totalPausedMinutes'] ?? 0,
      createdBy: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']['_id'] ?? '',
      notes: json['notes'],
      isDeleted: json['isDeleted'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert GameSession to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'totalAmount': totalAmount,
      'status': status,
      'totalPausedMinutes': totalPausedMinutes,
      'createdBy': createdBy,
      'notes': notes,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get session status display text
  String get statusText {
    switch (status) {
      case 'active':
        return 'Active';
      case 'paused':
        return 'Paused';
      case 'completed':
        return 'Completed';
      case 'billed':
        return 'Billed';
      default:
        return status;
    }
  }

  /// Check if session is currently active
  bool get isActive => status == 'active';

  /// Check if session is paused
  bool get isPaused => status == 'paused';

  /// Check if session is ended
  bool get isEnded => status == 'completed' || status == 'billed';

  /// Copy with method for immutability
  GameSession copyWith({
    String? id,
    int? tableNumber,
    String? customerName,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    double? totalAmount,
    String? status,
    int? totalPausedMinutes,
    String? createdBy,
    String? notes,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameSession(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      totalPausedMinutes: totalPausedMinutes ?? this.totalPausedMinutes,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
