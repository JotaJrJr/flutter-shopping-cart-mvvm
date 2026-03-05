import 'package:flutter/material.dart';

import '../../domain/entities/cart.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/load_products_use_case.dart';
import '../../domain/usecases/sync_cart_use_case.dart';
import '../stores/cart_store.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/cart_badge_button.dart';

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
        _viewModel.updateCartCommand,
      ]),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Catalog'),
            actions: [CartBadgeButton(cartStore: widget.cartStore)],
          ),
          body: Column(
            children: [
              if (_viewModel.updateCartCommand.error != null)
                _InlineError(
                  message: _viewModel.updateCartCommand.error!.message,
                  onClose: _viewModel.updateCartCommand.clearError,
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

            return _ProductCard(
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.isBusy,
    required this.cart,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
    );
  }
}

class QuantityControl extends StatefulWidget {
  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  State<QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<QuantityControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 1,
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void didUpdateWidget(QuantityControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: widget.onDecrement,
            icon: const Icon(Icons.remove),
          ),
          ScaleTransition(
            scale: _animation,
            child: Text(
              '${widget.quantity}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: widget.onIncrement,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE1DA),
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
        trailing: IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
      ),
    );
  }
}
