import 'game_session.dart';

/// Response model for stopping a game session
class StopSessionResponse {
  final GameSession session;
  final int durationMinutes;
  final double totalAmount;
  final double pricePerMinute;

  StopSessionResponse({
    required this.session,
    required this.durationMinutes,
    required this.totalAmount,
    required this.pricePerMinute,
  });

  /// Factory constructor to create from JSON
  factory StopSessionResponse.fromJson(Map<String, dynamic> json) {
    return StopSessionResponse(
      session: GameSession.fromJson(json['session'] as Map<String, dynamic>),
      durationMinutes: json['durationMinutes'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      pricePerMinute: (json['pricePerMinute'] ?? 0).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'session': session.toJson(),
      'durationMinutes': durationMinutes,
      'totalAmount': totalAmount,
      'pricePerMinute': pricePerMinute,
    };
  }
}
