/// Request model to create a game bill
class CreateGameBillRequest {
  final String sessionId;
  final double discount;
  final String createdBy;
  final String? notes;

  CreateGameBillRequest({
    required this.sessionId,
    this.discount = 0,
    required this.createdBy,
    this.notes,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'discount': discount,
      'createdBy': createdBy,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
