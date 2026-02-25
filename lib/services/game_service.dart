import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_config.dart';
import '../models/game_table.dart';
import '../models/game_session.dart';
import '../models/game_session_list_response.dart';
import '../models/stop_session_response.dart';
import '../models/game_bill.dart';
import '../models/game_bill_list_response.dart';
import '../models/create_game_bill_request.dart';
import 'auth_service.dart';

class GameService {
  static const String baseUrl = 'https://dars-resturant-management.vercel.app';

  // ==================== GAME CONFIGS ====================

  /// Get all game configurations
  static Future<List<GameConfig>> getAllGameConfigs() async {
    try {
      final uri = Uri.parse('$baseUrl/game/config');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => GameConfig.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load game configs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching game configs: $e');
    }
  }

  // ==================== TENNIS TABLES ====================

  /// Get all tennis table statuses
  static Future<List<GameTable>> getTennisTableStatuses() async {
    try {
      final uri = Uri.parse('$baseUrl/game/tennis/tables');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => GameTable.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tennis tables: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tennis tables: $e');
    }
  }

  // ==================== SNOOKER TABLES ====================

  /// Get all snooker table statuses
  static Future<List<GameTable>> getSnookerTableStatuses() async {
    try {
      final uri = Uri.parse('$baseUrl/game/snooker/tables');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => GameTable.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load snooker tables: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching snooker tables: $e');
    }
  }

  // ==================== TENNIS SESSIONS ====================

  /// Get all tennis sessions with pagination
  static Future<GameSessionListResponse> getTennisSessions({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/game/tennis/sessions').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GameSessionListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to load tennis sessions: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching tennis sessions: $e');
    }
  }

  /// Get tennis session by ID
  static Future<GameSession> getTennisSessionById(String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/game/tennis/sessions/$sessionId');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GameSession.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to load tennis session: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching tennis session: $e');
    }
  }

  /// Start a new tennis session
  static Future<GameSession> startTennisSession({
    required int tableNumber,
    required String customerName,
    required String createdBy,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/game/tennis/sessions');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = jsonEncode({
        'tableNumber': tableNumber,
        'customerName': customerName,
        'createdBy': createdBy,
        'notes': notes,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GameSession.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to start tennis session: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error starting tennis session: $e');
    }
  }

  /// Stop a tennis session
  static Future<StopSessionResponse> stopTennisSession(String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/game/tennis/sessions/$sessionId/stop');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return StopSessionResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to stop tennis session: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error stopping tennis session: $e');
    }
  }

  // ==================== SNOOKER SESSIONS ====================

  /// Get all snooker sessions with pagination
  static Future<GameSessionListResponse> getSnookerSessions({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/game/snooker/sessions').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GameSessionListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to load snooker sessions: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching snooker sessions: $e');
    }
  }

  /// Get snooker session by ID
  static Future<GameSession> getSnookerSessionById(String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/game/snooker/sessions/$sessionId');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GameSession.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to load snooker session: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching snooker session: $e');
    }
  }

  /// Start a new snooker session
  static Future<GameSession> startSnookerSession({
    required int tableNumber,
    required String customerName,
    required String createdBy,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/game/snooker/sessions');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = jsonEncode({
        'tableNumber': tableNumber,
        'customerName': customerName,
        'createdBy': createdBy,
        'notes': notes,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GameSession.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to start snooker session: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error starting snooker session: $e');
    }
  }

  /// Stop a snooker session
  static Future<StopSessionResponse> stopSnookerSession(
    String sessionId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/game/snooker/sessions/$sessionId/stop');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return StopSessionResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to stop snooker session: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error stopping snooker session: $e');
    }
  }

  // ==================== TENNIS BILLS ====================

  /// Create a tennis bill
  static Future<GameBill> createTennisBill({
    required String sessionId,
    required String createdBy,
    double discount = 0,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/game/bills/tennis');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = jsonEncode({
        'sessionId': sessionId,
        'discount': discount,
        'createdBy': createdBy,
        'notes': notes,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GameBill.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create tennis bill: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating tennis bill: $e');
    }
  }

  // ==================== SNOOKER BILLS ====================

  /// Create a snooker bill
  static Future<GameBill> createSnookerBill({
    required String sessionId,
    required String createdBy,
    int gameCount = 1,
    double discount = 0,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/game/bills/snooker');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = jsonEncode({
        'sessionId': sessionId,
        'gameCount': gameCount,
        'discount': discount,
        'createdBy': createdBy,
        'notes': notes,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GameBill.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to create snooker bill: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating snooker bill: $e');
    }
  }

  // ==================== GAME BILLS ====================

  /// Get all game bills with pagination
  static Future<GameBillListResponse> getAllGameBills({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/game/bills').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GameBillListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load game bills: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching game bills: $e');
    }
  }

  /// Get game bill by ID
  static Future<GameBill> getGameBillById(String billId) async {
    try {
      final uri = Uri.parse('$baseUrl/game/bills/$billId');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GameBill.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load game bill: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching game bill: $e');
    }
  }

  /// Get game bill by bill number
  static Future<GameBill> getGameBillByNumber(String billNumber) async {
    try {
      final uri = Uri.parse('$baseUrl/game/bills/number/$billNumber');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GameBill.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load game bill: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching game bill: $e');
    }
  }

  /// Mark a game bill as paid
  static Future<GameBill> markGameBillAsPaid(
    String billId, {
    required String paymentMethodId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/game/bills/$billId/pay');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final body = jsonEncode({'paidOn': paymentMethodId});

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return GameBill.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to mark bill as paid: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking bill as paid: $e');
    }
  }

  /// Refund a game bill
  static Future<GameBill> refundGameBill(String billId) async {
    try {
      final uri = Uri.parse('$baseUrl/game/bills/$billId/refund');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return GameBill.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to refund bill: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error refunding bill: $e');
    }
  }

  /// Delete a game bill
  static Future<bool> deleteGameBill(String billId) async {
    try {
      final uri = Uri.parse('$baseUrl/game/bills/$billId');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete bill: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting bill: $e');
    }
  }
}
