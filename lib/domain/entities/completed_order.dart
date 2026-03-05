import 'cart_item.dart';

class CompletedOrder {
  const CompletedOrder({required this.items, required this.createdAt});

  final List<CartItem> items;
  final DateTime createdAt;

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold<double>(0, (sum, item) => sum + item.subtotal);
  double get total => subtotal;
}
