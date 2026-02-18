import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;
  List<String> selectedModifiers;
  String? specialInstructions;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.specialInstructions,
  });

  double get totalPrice {
    double modifiersCost = selectedModifiers.length * 0.5;
    return (menuItem.price + modifiersCost * quantity);
  }
}
