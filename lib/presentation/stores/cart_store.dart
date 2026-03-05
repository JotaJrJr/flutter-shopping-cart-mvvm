import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/completed_order.dart';
import '../../domain/entities/product.dart';

class CartStore {
  static const int maxDistinctProducts = 10;
  static const int maxQuantityPerProduct = 10;

  final ValueNotifier<Cart> cart = ValueNotifier<Cart>(const Cart.empty());

  CompletedOrder? _lastCompletedOrder;

  CompletedOrder? get lastCompletedOrder => _lastCompletedOrder;

  Cart snapshot() {
    return Cart(
      items: List<CartItem>.unmodifiable(cart.value.items),
      isLocked: cart.value.isLocked,
    );
  }

  void restore(Cart snapshot) {
    _updateCart(snapshot);
  }

  Result<void> increment(Product product) {
    final editable = _validateEditable();
    if (editable case Failure<void>()) {
      return editable;
    }

    final currentItems = List<CartItem>.from(cart.value.items);
    final index = currentItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    final canAddDistinctProduct = index != -1 || cart.value.totalDistinctItems < maxDistinctProducts;

    if (!canAddDistinctProduct) {
      return const Failure<void>(
        AppException('Somente 10 produtos podem ser adicionados ao carrinho.'),
      );
    }

    if (index == -1) {
      currentItems.add(CartItem(product: product, quantity: 1));
    } else {
      final item = currentItems[index];

      if (item.quantity >= maxQuantityPerProduct) {
        return const Failure<void>(
          AppException('Um produto não pode ter mais do que 10 unidades no carrinho.'),
        );
      }

      currentItems[index] = CartItem(
        product: item.product,
        quantity: item.quantity + 1,
      );
    }

    _updateCart(Cart(items: currentItems, isLocked: false));
    return const Success<void>(null);
  }

  Result<void> decrement(Product product) {
    final editable = _validateEditable();
    if (editable case Failure<void>()) {
      return editable;
    }

    final currentItems = List<CartItem>.from(cart.value.items);
    final index = currentItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index == -1) {
      return const Success<void>(null);
    }

    final item = currentItems[index];

    if (item.quantity <= 1) {
      currentItems.removeAt(index);
    } else {
      currentItems[index] = CartItem(
        product: item.product,
        quantity: item.quantity - 1,
      );
    }

    _updateCart(Cart(items: currentItems, isLocked: false));
    return const Success<void>(null);
  }

  Result<void> remove(Product product) {
    final editable = _validateEditable();
    if (editable case Failure<void>()) {
      return editable;
    }

    final currentItems = cart.value.items
        .where((item) => item.product.id != product.id)
        .toList();

    _updateCart(Cart(items: currentItems, isLocked: false));
    return const Success<void>(null);
  }

  Result<void> lockForCompletedCheckout() {
    final editable = _validateEditable();
    if (editable case Failure<void>()) {
      return editable;
    }

    if (cart.value.isEmpty) {
      return const Failure<void>(
        AppException('Adicione ao menos 1 produto para finalizar o pedido.'),
      );
    }

    final snapshot = List<CartItem>.from(cart.value.items);
    _lastCompletedOrder = CompletedOrder(
      items: snapshot,
      createdAt: DateTime.now(),
    );

    _updateCart(Cart(items: snapshot, isLocked: true));

    return const Success<void>(null);
  }

  void startNewRequest() {
    _lastCompletedOrder = null;
    _updateCart(const Cart.empty());
  }

  int quantityFor(Product product) {
    for (final item in cart.value.items) {
      if (item.product.id == product.id) {
        return item.quantity;
      }
    }
    return 0;
  }

  Result<void> _validateEditable() {
    if (cart.value.isLocked) {
      return const Failure<void>(
        AppException('Um carrinho finalizado não pode ser editado. Inicie uma nova solicitação.'),
      );
    }

    return const Success<void>(null);
  }

  void _updateCart(Cart nextCart) {
    cart.value = Cart(
      items: List<CartItem>.unmodifiable(nextCart.items),
      isLocked: nextCart.isLocked,
    );
  }
}
