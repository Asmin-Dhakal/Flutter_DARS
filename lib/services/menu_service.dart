import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import 'auth_service.dart';

class MenuService {
  static const String baseUrl = 'https://dars-resturant-management.vercel.app';

  /// Get all menu items with optional filters
  static Future<List<MenuItem>> getAllMenuItems({
    int? page,
    int? limit,
    String? itemType,
    bool? getAll,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (itemType != null && itemType.isNotEmpty) {
        queryParams['itemType'] = itemType;
      }
      if (getAll != null) queryParams['getAll'] = getAll.toString();

      // Build URL with query params
      final uri = Uri.parse(
        '$baseUrl/cafe/menu-items',
      ).replace(queryParameters: queryParams);

      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('DEBUG: Fetching menu items from $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Menu items response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // Handle different response formats (likely {docs: [...]})
        List<dynamic> itemsJson;

        if (data is List) {
          itemsJson = data;
        } else if (data is Map) {
          if (data.containsKey('docs')) {
            itemsJson = data['docs'] as List;
          } else if (data.containsKey('data')) {
            itemsJson = data['data'] as List;
          } else if (data.containsKey('menuItems')) {
            itemsJson = data['menuItems'] as List;
          } else {
            // Try to find any list in the object
            for (var value in data.values) {
              if (value is List) {
                itemsJson = value;
                break;
              }
            }
            throw Exception(
              'Unexpected response format. Keys: ${data.keys.toList()}',
            );
          }
        } else {
          throw Exception('Unexpected response type: ${data.runtimeType}');
        }

        // Filter out deleted items
        final items = itemsJson
            .map((json) => MenuItem.fromJson(json))
            .where((item) => item.isDeleted != true)
            .toList();

        return items;
      } else {
        String errorMessage;
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['message'] ??
              error['error'] ??
              'Failed to fetch menu items';
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Error fetching menu items: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get menu items by type/category
  static Future<List<MenuItem>> getMenuItemsByType(String itemType) async {
    return getAllMenuItems(itemType: itemType, getAll: true);
  }

  /// Get available item types/categories
  static Future<List<String>> getItemTypes() async {
    final items = await getAllMenuItems(getAll: true);
    final types = items
        .where((item) => item.itemType != null)
        .map((item) => item.itemType!)
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  // Change from: Future<MenuItem> getMenuItemById
  // To: static Future<MenuItem> getMenuItemById
  static Future<MenuItem> getMenuItemById(String id) async {
    final token = await AuthService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = await http.get(
      Uri.parse('$baseUrl/cafe/menu-items/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return MenuItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load menu item: ${response.body}');
    }
  }

  // Change from: Future<Map<String, MenuItem>> getMenuItemsByIds
  // To: static Future<Map<String, MenuItem>> getMenuItemsByIds
  static Future<Map<String, MenuItem>> getMenuItemsByIds(
    List<String> ids,
  ) async {
    final Map<String, MenuItem> items = {};

    // Remove duplicates
    final uniqueIds = ids.toSet().toList();

    // Fetch all items in parallel
    await Future.wait(
      uniqueIds.map((id) async {
        try {
          final item = await getMenuItemById(id);
          items[id] = item;
        } catch (e) {
          print('Error fetching menu item $id: $e');
          // Create placeholder for failed items
          items[id] = MenuItem(
            id: id,
            name: 'Unknown Item',
            itemType: '',
            price: 0,
            isDeleted: false,
          );
        }
      }),
    );

    return items;
  }
}
