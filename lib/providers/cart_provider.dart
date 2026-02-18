import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  String _tableNumber = '';
  String _customerName = '';

  List<CartItem> get items {
    print('DEBUG: Getting items, count: ${_items.length}'); // Debug print
    return List.unmodifiable(_items);
  }

  String get tableNumber => _tableNumber;
  String get customerName => _customerName;

  int get itemCount {
    final count = _items.fold(0, (sum, item) => sum + item.quantity);
    print('DEBUG: Item count: $count'); // Debug print
    return count;
  }

  double get totalAmount {
    final total = _items.fold(0.0, (sum, item) => sum + item.totalPrice);
    print('DEBUG: Total amount: $total'); // Debug print
    return total;
  }

  void setTableInfo(String table, {String? customer}) {
    _tableNumber = table;
    if (customer != null) _customerName = customer;
    print('DEBUG: Table set to: $table'); // Debug print
    notifyListeners();
  }

  void addToCart(
    MenuItem menuItem, {
    List<String> modifiers = const [],
    String? instructions,
  }) {
    print('DEBUG: Adding ${menuItem.name} to cart'); // Debug print

    // Check if item already exists with same modifiers
    final existingIndex = _items.indexWhere(
      (item) =>
          item.menuItem.id == menuItem.id &&
          _listEquals(item.selectedModifiers, modifiers),
    );

    if (existingIndex >= 0) {
      print('DEBUG: Item exists, incrementing quantity'); // Debug print
      _items[existingIndex].quantity++;
    } else {
      print('DEBUG: New item, adding to cart'); // Debug print
      _items.add(
        CartItem(
          menuItem: menuItem,
          selectedModifiers: modifiers,
          specialInstructions: instructions,
        ),
      );
    }

    print('DEBUG: Cart now has ${_items.length} items'); // Debug print
    notifyListeners(); // CRITICAL: This must be called!
  }

  void removeFromCart(int index) {
    print('DEBUG: Removing item at index $index'); // Debug print
    _items.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    print('DEBUG: Updating quantity at $index to $quantity'); // Debug print
    if (quantity <= 0) {
      removeFromCart(index);
    } else {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    print('DEBUG: Clearing cart'); // Debug print
    _items.clear();
    _tableNumber = '';
    _customerName = '';
    notifyListeners();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = [...a]..sort();
    final sortedB = [...b]..sort();
    return sortedA.join(',') == sortedB.join(',');
  }
}
