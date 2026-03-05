import 'package:flutter/foundation.dart';

import '../../core/command.dart';
import '../../core/errors/app_exception.dart';
import '../../core/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/sync_cart_use_case.dart';
import '../stores/cart_store.dart';

class ProductViewModel extends ChangeNotifier {
  ProductViewModel({
    required CartStore cartStore,
    required SyncCartUseCase syncCartUseCase,
    required Product product,
  }) : _cartStore = cartStore,
       _syncCartUseCase = syncCartUseCase,
       _product = product {
    _quantity = cartStore.quantityFor(product);
    
    adicionarProdutoCommand = AdicionarProdutoCommand<Product>(
      _incrementProduct,
    );
    removerProdutoCommand = RemoverProdutoCommand<Product>(
      _decrementProduct,
    );
  }

  final CartStore _cartStore;
  final SyncCartUseCase _syncCartUseCase;
  final Product _product;

  int _quantity = 0;
  bool _isUpdating = false;

  Product get product => _product;
  int get quantity => _quantity;
  bool get isUpdating => _isUpdating;
  bool get isUpdateCartRunning => adicionarProdutoCommand.running || removerProdutoCommand.running;
  AppException? get updateCartError => adicionarProdutoCommand.error ?? removerProdutoCommand.error;

  late final AdicionarProdutoCommand<Product> adicionarProdutoCommand;
  late final RemoverProdutoCommand<Product> removerProdutoCommand;

  Future<Result<void>> _updateCart({
    required Product product,
    required ProductCartMutationType mutationType,
  }) async {
    _setIsUpdating(true);

    try {
      final previousCart = _cartStore.snapshot();
      final localResult = mutationType == ProductCartMutationType.increment
          ? _cartStore.increment(product)
          : _cartStore.decrement(product);

      if (localResult case Failure<void>()) {
        return localResult;
      }

      final syncResult = await _syncCartUseCase.execute(_cartStore.cart.value);

      if (syncResult case Failure<void>()) {
        _cartStore.restore(previousCart);
        return syncResult;
      }

      _quantity = _cartStore.quantityFor(product);
      return const Success<void>(null);
    } finally {
      _setIsUpdating(false);
    }
  }

  Future<Result<void>> _incrementProduct(Product product) {
    return _updateCart(
      product: product,
      mutationType: ProductCartMutationType.increment,
    );
  }

  Future<Result<void>> _decrementProduct(Product product) {
    return _updateCart(
      product: product,
      mutationType: ProductCartMutationType.decrement,
    );
  }

  Future<Result<void>> incrementProduct() => adicionarProdutoCommand.execute(_product);
  Future<Result<void>> decrementProduct() => removerProdutoCommand.execute(_product);

  void clearUpdateCartError() {
    adicionarProdutoCommand.clearError();
    removerProdutoCommand.clearError();
  }

  void _setIsUpdating(bool isUpdating) {
    if (_isUpdating == isUpdating) return;
    
    _isUpdating = isUpdating;
    notifyListeners();
  }

  void refreshQuantity() {
    _quantity = _cartStore.quantityFor(_product);
    notifyListeners();
  }

  @override
  void dispose() {
    adicionarProdutoCommand.dispose();
    removerProdutoCommand.dispose();
    super.dispose();
  }
}

enum ProductCartMutationType { increment, decrement }