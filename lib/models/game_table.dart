/// Game table model
class GameTable {
  final int tableNumber;
  final bool isOccupied;

  GameTable({required this.tableNumber, required this.isOccupied});

  /// Factory constructor to create GameTable from JSON
  factory GameTable.fromJson(Map<String, dynamic> json) {
    return GameTable(
      tableNumber: json['tableNumber'] ?? 0,
      isOccupied: json['isOccupied'] ?? false,
    );
  }

  /// Convert GameTable to JSON
  Map<String, dynamic> toJson() {
    return {'tableNumber': tableNumber, 'isOccupied': isOccupied};
  }

  /// Get status display text
  String get statusText => isOccupied ? 'Occupied' : 'Free';

  /// Copy with method for immutability
  GameTable copyWith({int? tableNumber, bool? isOccupied}) {
    return GameTable(
      tableNumber: tableNumber ?? this.tableNumber,
      isOccupied: isOccupied ?? this.isOccupied,
    );
  }
}
