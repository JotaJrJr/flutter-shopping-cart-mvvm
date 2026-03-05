import 'package:flutter/material.dart';
import 'package:shoppin_cart_mvvm/app/routes/app_routes.dart';
import 'package:shoppin_cart_mvvm/presentation/widgets/inline_error.dart';

import '../../domain/entities/cart.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/load_products_use_case.dart';
import '../../domain/usecases/sync_cart_use_case.dart';
import '../stores/cart_store.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/quantity_control.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.cartStore,
    required this.loadProductsUseCase,
    required this.syncCartUseCase,
  });

  final CartStore cartStore;
  final LoadProductsUseCase loadProductsUseCase;
  final SyncCartUseCase syncCartUseCase;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      cartStore: widget.cartStore,
      loadProductsUseCase: widget.loadProductsUseCase,
      syncCartUseCase: widget.syncCartUseCase,
    );
    _viewModel.loadProducts();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _viewModel,
        _viewModel.loadProductsCommand,
        _viewModel.adicionarProdutoCommand,
        _viewModel.removerProdutoCommand,
      ]),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Catálogo'),
            actions: [CartBadgeButton(cartStore: widget.cartStore)],
          ),
          body: Column(
            children: [
              if (_viewModel.updateCartError != null)
                InlineError(
                  message: _viewModel.updateCartError!.message,
                  onClose: _viewModel.clearUpdateCartError,
                ),
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.loadProductsCommand.running && _viewModel.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.loadProductsCommand.error != null &&
        _viewModel.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _viewModel.loadProductsCommand.error!.message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _viewModel.loadProducts,
                child: const Text('Tente nonvamente'),
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder<Cart>(
      valueListenable: widget.cartStore.cart,
      builder: (context, cart, child) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _viewModel.products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = _viewModel.products[index];
            final quantity = widget.cartStore.quantityFor(product);

            return ProductCard(
              product: product,
              quantity: quantity,
              isBusy: _viewModel.isUpdatingProduct(product),
              cart: cart,
              onAdd: () => _viewModel.incrementProduct(product),
              onIncrement: () => _viewModel.incrementProduct(product),
              onDecrement: () => _viewModel.decrementProduct(product),
            );
          },
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.quantity,
    required this.isBusy,
    required this.cart,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });

  final Product product;
  final int quantity;
  final bool isBusy;
  final Cart cart;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final canAddNewProduct = quantity > 0 || cart.totalDistinctItems < 10;
    final canIncrement = quantity < CartStore.maxQuantityPerProduct;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.product, arguments: product);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Hero(
                  tag: 'product_image_${product.id}',
                  child: Image.network(
                    product.imageUrl,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 88,
                      height: 88,
                      color: const Color(0xFFE3DED2),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF0C6D62),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (quantity == 0)
                      FilledButton(
                        onPressed: isBusy || !canAddNewProduct ? null : onAdd,
                        child: const Text('Adicionar ao carrinho'),
                      )
                    else
                      QuantityControl(
                        quantity: quantity,
                        onIncrement: isBusy || !canIncrement ? null : onIncrement,
                        onDecrement: isBusy ? null : onDecrement,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
