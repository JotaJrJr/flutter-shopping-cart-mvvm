import 'package:flutter/material.dart';
import 'package:shoppin_cart_mvvm/domain/entities/product.dart';
import 'package:shoppin_cart_mvvm/presentation/stores/cart_store.dart';
import 'package:shoppin_cart_mvvm/presentation/viewmodels/product_view_model.dart';
import 'package:shoppin_cart_mvvm/presentation/widgets/inline_error.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({
    super.key,
    required this.product,
    required this.cartStore,
    required this.viewModel,
  });

  final Product product;
  final CartStore cartStore;
  final ProductViewModel viewModel;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final ProductViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel;
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
        _viewModel.adicionarProdutoCommand,
        _viewModel.removerProdutoCommand,
        widget.cartStore.cart,
      ]),
      builder: (context, child) {
        final cart = widget.cartStore.cart.value;
        final canAddNewProduct = _viewModel.quantity > 0 || cart.totalDistinctItems < 10;
        final canIncrement = _viewModel.quantity < CartStore.maxQuantityPerProduct;

        return Scaffold(
          appBar: AppBar(
            title: Text(_viewModel.product.title),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          body: Column(
            children: [
              if (_viewModel.updateCartError != null)
                InlineError(
                  message: _viewModel.updateCartError!.message,
                  onClose: _viewModel.clearUpdateCartError,
                ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagem com Hero
                            Center(
                              child: Hero(
                                tag: 'product_image_${_viewModel.product.id}',
                                child: Container(
                                  height: 300,
                                  width: 300,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color(0xFFF8F9FA),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _viewModel.product.imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Categoria e preço
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _viewModel.product.category.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Descrição',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${_viewModel.product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0C6D62),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Descrição
                            Text(
                              _viewModel.product.description,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Rating
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _viewModel.product.rating.rate.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_viewModel.product.rating.count} avaliações',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(
            context,
            canAddNewProduct: canAddNewProduct,
            canIncrement: canIncrement,
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context, {
    required bool canAddNewProduct,
    required bool canIncrement,
  }) {
    final isBusy = _viewModel.isUpdating;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '\$${(_viewModel.product.price * _viewModel.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _viewModel.quantity == 0
                  ? FilledButton(
                      onPressed: isBusy || !canAddNewProduct
                          ? null
                          : () => _viewModel.incrementProduct(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isBusy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Adicionar ao carrinho'),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: isBusy
                                ? null
                                : () => _viewModel.decrementProduct(),
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            _viewModel.quantity.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: isBusy || !canIncrement
                                ? null
                                : () => _viewModel.incrementProduct(),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}