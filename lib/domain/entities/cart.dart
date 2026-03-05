import 'cart_item.dart';

class Cart {
  const Cart({required this.items, required this.isLocked});

  const Cart.empty() : items = const <CartItem>[], isLocked = false;

  final List<CartItem> items;
  final bool isLocked;

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);
  int get totalDistinctItems => items.length;
  double get subtotal => items.fold<double>(0, (sum, item) => sum + item.subtotal);
  double get total => subtotal;
  bool get isEmpty => items.isEmpty;
}
