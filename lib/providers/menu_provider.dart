import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';

class MenuProvider with ChangeNotifier {
  List<MenuItem> _menuItems = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';

  List<MenuItem> get menuItems => _menuItems;
  List<String> get categories => ['All', ..._categories];
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  List<MenuItem> get filteredItems {
    if (_selectedCategory == 'All') return _menuItems;
    return _menuItems
        .where((item) => item.itemType == _selectedCategory)
        .toList();
  }

  /// Load all menu items
  Future<void> loadMenuItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _menuItems = await MenuService.getAllMenuItems(getAll: true);

      // Extract unique categories
      _categories = _menuItems
          .where((item) => item.itemType != null)
          .map((item) => item.itemType!)
          .toSet()
          .toList();
      _categories.sort();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Select category
  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Get item by ID
  MenuItem? getItemById(String id) {
    try {
      return _menuItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
