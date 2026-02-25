/// Game configuration model
class GameConfig {
  final String id;
  final String gameType;
  final int numberOfTables;
  final double pricePerUnit;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameConfig({
    required this.id,
    required this.gameType,
    required this.numberOfTables,
    required this.pricePerUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create GameConfig from JSON
  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      id: json['_id'] ?? '',
      gameType: json['gameType'] ?? '',
      numberOfTables: json['numberOfTables'] ?? 0,
      pricePerUnit: (json['pricePerUnit'] ?? 0).toDouble(),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert GameConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'gameType': gameType,
      'numberOfTables': numberOfTables,
      'pricePerUnit': pricePerUnit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get display name for the game
  String get displayName {
    if (gameType == 'table-tennis') return 'Table Tennis';
    if (gameType == 'snooker-pool') return 'Snooker & Pool';
    return gameType;
  }
}
