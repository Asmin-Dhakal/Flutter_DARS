import 'game_bill.dart';

/// Game bill list response model (for paginated API responses)
class GameBillListResponse {
  final List<GameBill> docs;
  final int totalDocs;
  final int limit;
  final int totalPages;
  final int page;
  final int pagingCounter;
  final bool hasPrevPage;
  final bool hasNextPage;
  final int? prevPage;
  final int? nextPage;

  GameBillListResponse({
    required this.docs,
    required this.totalDocs,
    required this.limit,
    required this.totalPages,
    required this.page,
    required this.pagingCounter,
    required this.hasPrevPage,
    required this.hasNextPage,
    this.prevPage,
    this.nextPage,
  });

  /// Factory constructor to create from JSON
  factory GameBillListResponse.fromJson(Map<String, dynamic> json) {
    return GameBillListResponse(
      docs:
          (json['docs'] as List<dynamic>?)
              ?.map((e) => GameBill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalDocs: json['totalDocs'] ?? 0,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
      pagingCounter: json['pagingCounter'] ?? 1,
      hasPrevPage: json['hasPrevPage'] ?? false,
      hasNextPage: json['hasNextPage'] ?? false,
      prevPage: json['prevPage'],
      nextPage: json['nextPage'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'docs': docs.map((e) => e.toJson()).toList(),
      'totalDocs': totalDocs,
      'limit': limit,
      'totalPages': totalPages,
      'page': page,
      'pagingCounter': pagingCounter,
      'hasPrevPage': hasPrevPage,
      'hasNextPage': hasNextPage,
      'prevPage': prevPage,
      'nextPage': nextPage,
    };
  }

  /// Get total revenue from bills
  double get totalRevenue =>
      docs.fold(0, (sum, bill) => sum + bill.finalAmount);

  /// Get paid bills count
  int get paidBillsCount => docs.where((bill) => bill.isPaid).length;

  /// Get pending bills count
  int get pendingBillsCount => docs.where((bill) => bill.isPending).length;
}
