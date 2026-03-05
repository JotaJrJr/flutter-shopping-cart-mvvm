import 'package:flutter/foundation.dart';

import '../../core/command.dart';
import '../../core/errors/app_exception.dart';
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
       _checkoutUseCase = checkoutUseCase {
    adicionarProdutoCommand = AdicionarProdutoCommand<Product>(
      _incrementProduct,
    );
    decrementarProdutoCommand = RemoverProdutoCommand<Product>(
      _decrementProduct,
    );
    removerProdutoCommand = RemoverProdutoCommand<Product>(_removeProduct);
    checkoutCommand = FinalizarCompraCommand(_checkout);
  }

  final CartStore _cartStore;
  final SyncCartUseCase _syncCartUseCase;
  final CheckoutUseCase _checkoutUseCase;

  late final AdicionarProdutoCommand<Product> adicionarProdutoCommand;
  late final RemoverProdutoCommand<Product> decrementarProdutoCommand;
  late final RemoverProdutoCommand<Product> removerProdutoCommand;
  late final FinalizarCompraCommand checkoutCommand;

  bool get isUpdateCartRunning =>
      adicionarProdutoCommand.running ||
      decrementarProdutoCommand.running ||
      removerProdutoCommand.running;
  AppException? get updateCartError =>
      adicionarProdutoCommand.error ??
      decrementarProdutoCommand.error ??
      removerProdutoCommand.error;

  Future<Result<void>> _updateCart(
    CartMutationType mutationType,
    Product product,
  ) async {
    final previousCart = _cartStore.snapshot();
    final localResult = switch (mutationType) {
      CartMutationType.increment => _cartStore.increment(product),
      CartMutationType.decrement => _cartStore.decrement(product),
      CartMutationType.remove => _cartStore.remove(product),
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

  Future<Result<void>> _incrementProduct(Product product) {
    return _updateCart(CartMutationType.increment, product);
  }

  Future<Result<void>> _decrementProduct(Product product) {
    return _updateCart(CartMutationType.decrement, product);
  }

  Future<Result<void>> _removeProduct(Product product) {
    return _updateCart(CartMutationType.remove, product);
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

  Future<Result<void>> incrementProduct(Product product) =>
      adicionarProdutoCommand.execute(product);

  Future<Result<void>> decrementProduct(Product product) =>
      decrementarProdutoCommand.execute(product);

  Future<Result<void>> removeProduct(Product product) =>
      removerProdutoCommand.execute(product);

  Future<Result<void>> checkout() => checkoutCommand.execute();

  void clearUpdateCartError() {
    adicionarProdutoCommand.clearError();
    decrementarProdutoCommand.clearError();
    removerProdutoCommand.clearError();
  }

  @override
  void dispose() {
    adicionarProdutoCommand.dispose();
    decrementarProdutoCommand.dispose();
    removerProdutoCommand.dispose();
    checkoutCommand.dispose();
    super.dispose();
  }
}

enum CartMutationType { increment, decrement, remove }
