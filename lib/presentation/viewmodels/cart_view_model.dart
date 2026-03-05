import 'package:flutter/foundation.dart';

import '../../core/command.dart';
import '../../core/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/checkout_use_case.dart';
import '../../domain/usecases/sync_cart_use_case.dart';
import '../stores/cart_store.dart';

class CartViewModel extends ChangeNotifier {
  CartViewModel({
    required CartStore cartStore,
    required SyncCartUseCase syncCartUseCase,
    required CheckoutUseCase checkoutUseCase,
  }) : _cartStore = cartStore,
       _syncCartUseCase = syncCartUseCase,
       _checkoutUseCase = checkoutUseCase,
       updateCartCommand = Command1<CartMutation>(
         (mutation) async => const Success<void>(null),
       ),
       checkoutCommand = Command0(() async => const Success<void>(null)) {
    updateCartCommand = Command1<CartMutation>(_updateCart);
    checkoutCommand = Command0(_checkout);
  }

  final CartStore _cartStore;
  final SyncCartUseCase _syncCartUseCase;
  final CheckoutUseCase _checkoutUseCase;

  late Command1<CartMutation> updateCartCommand;
  late Command0 checkoutCommand;

  Future<Result<void>> _updateCart(CartMutation mutation) async {
    final previousCart = _cartStore.snapshot();
    final localResult = switch (mutation.type) {
      CartMutationType.increment => _cartStore.increment(mutation.product),
      CartMutationType.decrement => _cartStore.decrement(mutation.product),
      CartMutationType.remove => _cartStore.remove(mutation.product),
    };

    if (localResult case Failure<void>()) {
      return localResult;
    }

    final syncResult = await _syncCartUseCase.execute(_cartStore.cart.value);

    if (syncResult case Failure<void>()) {
      _cartStore.restore(previousCart);
      return syncResult;
    }

    return const Success<void>(null);
  }

  Future<Result<void>> _checkout() async {
    final checkoutResult = await _checkoutUseCase.execute(
      _cartStore.cart.value,
    );

    if (checkoutResult case Failure<void>()) {
      return checkoutResult;
    }

    return _cartStore.lockForCompletedCheckout();
  }

  Future<Result<void>> incrementProduct(Product product) {
    return updateCartCommand.execute(
      CartMutation(product: product, type: CartMutationType.increment),
    );
  }

  Future<Result<void>> decrementProduct(Product product) {
    return updateCartCommand.execute(
      CartMutation(product: product, type: CartMutationType.decrement),
    );
  }

  Future<Result<void>> removeProduct(Product product) {
    return updateCartCommand.execute(
      CartMutation(product: product, type: CartMutationType.remove),
    );
  }

  Future<Result<void>> checkout() => checkoutCommand.execute();

  @override
  void dispose() {
    updateCartCommand.dispose();
    checkoutCommand.dispose();
    super.dispose();
  }
}

enum CartMutationType { increment, decrement, remove }

class CartMutation {
  const CartMutation({required this.product, required this.type});

  final Product product;
  final CartMutationType type;
}
