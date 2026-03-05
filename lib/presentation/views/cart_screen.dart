import 'package:flutter/material.dart';
import 'package:shoppin_cart_mvvm/presentation/widgets/inline_error.dart';

import '../../app/routes/app_routes.dart';
import '../../core/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/checkout_use_case.dart';
import '../../domain/usecases/sync_cart_use_case.dart';
import '../stores/cart_store.dart';
import '../viewmodels/cart_view_model.dart';
import '../widgets/quantity_control.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.cartStore,
    required this.syncCartUseCase,
    required this.checkoutUseCase,
  });

  final CartStore cartStore;
  final SyncCartUseCase syncCartUseCase;
  final CheckoutUseCase checkoutUseCase;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CartViewModel(
      cartStore: widget.cartStore,
      syncCartUseCase: widget.syncCartUseCase,
      checkoutUseCase: widget.checkoutUseCase,
    );
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
        widget.cartStore.cart,
        _viewModel.adicionarProdutoCommand,
        _viewModel.decrementarProdutoCommand,
        _viewModel.removerProdutoCommand,
        _viewModel.checkoutCommand,
      ]),
      builder: (context, child) {
        final cart = widget.cartStore.cart.value;

        return Scaffold(
          appBar: AppBar(title: const Text('Cart')),
          body: cart.isEmpty
              ? const Center(child: Text('Seu carrinho está vazio.'))
              : Column(
                  children: [
                    if (_viewModel.updateCartError != null)
                      InlineError(
                        message: _viewModel.updateCartError!.message,
                        onClose: _viewModel.clearUpdateCartError,
                      ),
                    if (_viewModel.checkoutCommand.error != null)
                      InlineError(
                        message: _viewModel.checkoutCommand.error!.message,
                        onClose: _viewModel.checkoutCommand.clearError,
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return CartItemCard(
                            item: item,
                            isLocked: cart.isLocked,
                            isBusy:
                                _viewModel.isUpdatingProduct(item.product) ||
                                _viewModel.checkoutCommand.running,
                            onIncrement: () =>
                                _viewModel.incrementProduct(item.product),
                            onDecrement: () =>
                                _viewModel.decrementProduct(item.product),
                            onRemove: () =>
                                _viewModel.removeProduct(item.product),
                          );
                        },
                      ),
                    ),
                    CartSummary(
                      cart: cart,
                      isCheckoutRunning: _viewModel.checkoutCommand.running,
                      onCheckout: () async {
                        final navigator = Navigator.of(context);
                        final result = await _viewModel.checkout();
                        if (!mounted) {
                          return;
                        }

                        if (result is Success<void>) {
                          navigator.pushNamedAndRemoveUntil(
                            AppRoutes.orderComplete,
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    required this.item,
    required this.isLocked,
    required this.isBusy,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    super.key,
  });

  final CartItem item;
  final bool isLocked;
  final bool isBusy;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.product.imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 76,
                  height: 76,
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
                    item.product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('Unitário: \$${item.product.price.toStringAsFixed(2)}'),
                  Text('Subtotal: \$${item.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  if (isLocked)
                    Text(
                      'Quantidade: ${item.quantity}',
                      style: Theme.of(context).textTheme.titleSmall,
                    )
                  else
                    Row(
                      children: [
                        QuantityControl(
                          quantity: item.quantity,
                          onIncrement: isBusy ? null : onIncrement,
                          onDecrement: isBusy ? null : onDecrement,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: isBusy ? null : onRemove,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Deletar'),
                        ),
                      ],
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

class CartSummary extends StatelessWidget {
  const CartSummary({
    required this.cart,
    required this.isCheckoutRunning,
    required this.onCheckout,
    super.key,
  });

  final Cart cart;
  final bool isCheckoutRunning;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE1D8C8))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SummaryRow(label: 'Items', value: '${cart.totalItems}'),
            const SizedBox(height: 6),
            SummaryRow(
              label: 'Total',
              value: '\$${cart.total.toStringAsFixed(2)}',
              emphasize: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: cart.isLocked || isCheckoutRunning
                    ? null
                    : onCheckout,
                child: Text(
                  isCheckoutRunning ? 'Finalizando...' : 'Finalizar compra',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}
