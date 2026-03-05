import 'package:flutter/material.dart';
import 'package:shoppin_cart_mvvm/presentation/viewmodels/product_view_model.dart';
import 'package:shoppin_cart_mvvm/presentation/views/product_screen.dart';

import '../data/repositories/cart_sync_repository_impl.dart';
import '../data/repositories/checkout_repository_impl.dart';
import '../data/repositories/products_repository_impl.dart';
import '../data/services/cart_api.dart';
import '../data/services/checkout_api.dart';
import '../data/services/products_api.dart';
import '../domain/entities/product.dart';
import '../domain/usecases/checkout_use_case.dart';
import '../domain/usecases/load_products_use_case.dart';
import '../domain/usecases/sync_cart_use_case.dart';
import '../presentation/stores/cart_store.dart';
import '../presentation/views/cart_screen.dart';
import '../presentation/views/home_screen.dart';
import '../presentation/views/order_complete_screen.dart';
import 'routes/app_routes.dart';

class ShoppingCartApp extends StatefulWidget {
  const ShoppingCartApp({super.key});

  @override
  State<ShoppingCartApp> createState() => _ShoppingCartAppState();
}

class _ShoppingCartAppState extends State<ShoppingCartApp> {
  late final CartStore _cartStore;
  late final LoadProductsUseCase _loadProductsUseCase;
  late final SyncCartUseCase _syncCartUseCase;
  late final CheckoutUseCase _checkoutUseCase;

  @override
  void initState() {
    super.initState();

    _cartStore = CartStore();
    _loadProductsUseCase = LoadProductsUseCase(
      ProductsRepositoryImpl(ProductsApi()),
    );
    _syncCartUseCase = SyncCartUseCase(CartSyncRepositoryImpl(CartApi()));
    _checkoutUseCase = CheckoutUseCase(CheckoutRepositoryImpl(CheckoutApi()));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purchase Flow',
      initialRoute: AppRoutes.home,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.home:
            return MaterialPageRoute<void>(
              builder: (_) => HomeScreen(
                cartStore: _cartStore,
                loadProductsUseCase: _loadProductsUseCase,
                syncCartUseCase: _syncCartUseCase,
              ),
              settings: settings,
            );
          case AppRoutes.cart:
            return MaterialPageRoute<void>(
              builder: (_) => CartScreen(
                cartStore: _cartStore,
                syncCartUseCase: _syncCartUseCase,
                checkoutUseCase: _checkoutUseCase,
              ),
              settings: settings,
            );
          case AppRoutes.orderComplete:
            return MaterialPageRoute<void>(
              builder: (_) => OrderCompleteScreen(cartStore: _cartStore),
              settings: settings,
            );
          case AppRoutes.product:
            final product = settings.arguments;
            if (product is! Product) {
              return MaterialPageRoute<void>(
                builder: (_) => HomeScreen(
                  cartStore: _cartStore,
                  loadProductsUseCase: _loadProductsUseCase,
                  syncCartUseCase: _syncCartUseCase,
                ),
                settings: settings,
              );
            }
            return MaterialPageRoute<void>(
              builder: (_) =>
                  ProductScreen(
                    product: product,
                    cartStore: _cartStore,
                    viewModel: ProductViewModel(
                      product: product,
                      cartStore: _cartStore,
                      syncCartUseCase: _syncCartUseCase,
                    ),
                  ),
              settings: settings,
            );
          default:
            return MaterialPageRoute<void>(
              builder: (_) => HomeScreen(
                cartStore: _cartStore,
                loadProductsUseCase: _loadProductsUseCase,
                syncCartUseCase: _syncCartUseCase,
              ),
              settings: settings,
            );
        }
      },
    );
  }
}
