import 'game_session.dart';

/// Game session list response model (for paginated API responses)
class GameSessionListResponse {
  final List<GameSession> docs;
  final int totalDocs;
  final int limit;
  final int totalPages;
  final int page;
  final int pagingCounter;
  final bool hasPrevPage;
  final bool hasNextPage;
  final int? prevPage;
  final int? nextPage;

  GameSessionListResponse({
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
  factory GameSessionListResponse.fromJson(Map<String, dynamic> json) {
    return GameSessionListResponse(
      docs:
          (json['docs'] as List<dynamic>?)
              ?.map((e) => GameSession.fromJson(e as Map<String, dynamic>))
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
}
