/// Request model to pay a game bill
class PayGameBillRequest {
  final String billId;
  final String paymentMethodId;
  final double? adjustedAmount; // Optional: if different from finalAmount
  final String? notes;

  PayGameBillRequest({
    required this.billId,
    required this.paymentMethodId,
    this.adjustedAmount,
    this.notes,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'billId': billId,
      'paymentMethodId': paymentMethodId,
      if (adjustedAmount != null) 'adjustedAmount': adjustedAmount,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
