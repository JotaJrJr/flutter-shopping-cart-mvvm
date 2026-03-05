import 'package:flutter/foundation.dart';

import '../../core/command.dart';
import '../../core/errors/app_exception.dart';
import '../../core/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/load_products_use_case.dart';
import '../../domain/usecases/sync_cart_use_case.dart';
import '../stores/cart_store.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required CartStore cartStore,
    required LoadProductsUseCase loadProductsUseCase,
    required SyncCartUseCase syncCartUseCase,
  }) : _cartStore = cartStore,
       _loadProductsUseCase = loadProductsUseCase,
       _syncCartUseCase = syncCartUseCase {
    loadProductsCommand = ListarProdutosCommand(_loadProducts);
    adicionarProdutoCommand = AdicionarProdutoCommand<Product>(
      _incrementProduct,
    );
    removerProdutoCommand = RemoverProdutoCommand<Product>(_decrementProduct);
  }

  final CartStore _cartStore;
  final LoadProductsUseCase _loadProductsUseCase;
  final SyncCartUseCase _syncCartUseCase;

  List<Product> _products = const <Product>[];
  int? _updatingProductId;

  List<Product> get products => _products;
  int? get updatingProductId => _updatingProductId;
  bool get isUpdateCartRunning => adicionarProdutoCommand.running || removerProdutoCommand.running;
  AppException? get updateCartError => adicionarProdutoCommand.error ?? removerProdutoCommand.error;

  late final ListarProdutosCommand loadProductsCommand;
  late final AdicionarProdutoCommand<Product> adicionarProdutoCommand;
  late final RemoverProdutoCommand<Product> removerProdutoCommand;

  Future<Result<void>> _loadProducts() async {
    final result = await _loadProductsUseCase.execute();

    switch (result) {
      case Success<List<Product>>():
        _products = result.value;
        notifyListeners();
        return const Success<void>(null);
      case Failure<List<Product>>():
        return Failure<void>(result.error);
    }
  }

  Future<Result<void>> _updateCart({
    required Product product,
    required HomeCartMutationType mutationType,
  }) async {
    _setUpdatingProduct(product.id);

    try {
      final previousCart = _cartStore.snapshot();
      final localResult = mutationType == HomeCartMutationType.increment
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

      return const Success<void>(null);
    } finally {
      _setUpdatingProduct(null);
    }
  }

  Future<Result<void>> _incrementProduct(Product product) {
    return _updateCart(
      product: product,
      mutationType: HomeCartMutationType.increment,
    );
  }

  Future<Result<void>> _decrementProduct(Product product) {
    return _updateCart(
      product: product,
      mutationType: HomeCartMutationType.decrement,
    );
  }

  Future<Result<void>> loadProducts() => loadProductsCommand.execute();

  Future<Result<void>> incrementProduct(Product product) => adicionarProdutoCommand.execute(product);

  Future<Result<void>> decrementProduct(Product product) => removerProdutoCommand.execute(product);

  void clearUpdateCartError() {
    adicionarProdutoCommand.clearError();
    removerProdutoCommand.clearError();
  }

  bool isUpdatingProduct(Product product) => _updatingProductId == product.id;

  void _setUpdatingProduct(int? productId) {
    if (_updatingProductId == productId) {
      return;
    }

    _updatingProductId = productId;
    notifyListeners();
  }

  @override
  void dispose() {
    loadProductsCommand.dispose();
    adicionarProdutoCommand.dispose();
    removerProdutoCommand.dispose();
    super.dispose();
  }
}

enum HomeCartMutationType { increment, decrement }
