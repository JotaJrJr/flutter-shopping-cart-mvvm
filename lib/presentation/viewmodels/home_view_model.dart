import 'package:flutter/foundation.dart';

import '../../core/command.dart';
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
       _syncCartUseCase = syncCartUseCase,
       loadProductsCommand = Command0(() async => const Success<void>(null)),
       updateCartCommand = Command1<HomeCartMutation>(
         (mutation) async => const Success<void>(null),
       ) {
    loadProductsCommand = Command0(_loadProducts);
    updateCartCommand = Command1<HomeCartMutation>(_updateCart);
  }

  final CartStore _cartStore;
  final LoadProductsUseCase _loadProductsUseCase;
  final SyncCartUseCase _syncCartUseCase;

  List<Product> _products = const <Product>[];
  int? _updatingProductId;

  List<Product> get products => _products;
  int? get updatingProductId => _updatingProductId;

  late Command0 loadProductsCommand;
  late Command1<HomeCartMutation> updateCartCommand;

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

  Future<Result<void>> _updateCart(HomeCartMutation mutation) async {
    _setUpdatingProduct(mutation.product.id);

    try {
      final previousCart = _cartStore.snapshot();
      final localResult = mutation.type == HomeCartMutationType.increment
          ? _cartStore.increment(mutation.product)
          : _cartStore.decrement(mutation.product);

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

  Future<Result<void>> loadProducts() => loadProductsCommand.execute();

  Future<Result<void>> incrementProduct(Product product) {
    return updateCartCommand.execute(
      HomeCartMutation(product: product, type: HomeCartMutationType.increment),
    );
  }

  Future<Result<void>> decrementProduct(Product product) {
    return updateCartCommand.execute(
      HomeCartMutation(product: product, type: HomeCartMutationType.decrement),
    );
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
    updateCartCommand.dispose();
    super.dispose();
  }
}

enum HomeCartMutationType { increment, decrement }

class HomeCartMutation {
  const HomeCartMutation({required this.product, required this.type});

  final Product product;
  final HomeCartMutationType type;
}
