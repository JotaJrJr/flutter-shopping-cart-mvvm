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

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((x) => x.toMap()).toList(),
      'isLocked': isLocked,
    };
  }

  factory Cart.fromMap(Map<String, dynamic> map) {
    return Cart(
      items: List<CartItem>.from(
        (map['items'] as List).map((x) => CartItem.fromMap(x as Map<String, dynamic>)),
      ),
      isLocked: map['isLocked'] as bool,
    );
  }
}
