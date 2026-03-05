import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/completed_order.dart';
import '../stores/cart_store.dart';

class OrderCompleteScreen extends StatelessWidget {
  const OrderCompleteScreen({super.key, required this.cartStore});

  final CartStore cartStore;

  @override
  Widget build(BuildContext context) {
    final order = cartStore.lastCompletedOrder;

    if (order == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pedido concluído'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido realizado',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Criado em ${_formatDate(order.createdAt)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...order.items.map((item) => _OrderItemCard(item: item)),
              ],
            ),
          ),
          _OrderSummary(
            order: order,
            onNewRequest: () {
              cartStore.startNewRequest();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.product.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 56,
              height: 56,
              color: const Color(0xFFE3DED2),
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined),
            ),
          ),
        ),
        title: Text(
          item.product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Qtd ${item.quantity}  |  Unit \$${item.product.price.toStringAsFixed(2)}',
        ),
        trailing: Text('\$${item.subtotal.toStringAsFixed(2)}'),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order, required this.onNewRequest});

  final CompletedOrder order;
  final VoidCallback onNewRequest;

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
            _SummaryRow(label: 'Itens', value: '${order.totalItems}'),
            const SizedBox(height: 6),
            _SummaryRow(
              label: 'Subtotal',
              value: '\$${order.subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            _SummaryRow(
              label: 'Total',
              value: '\$${order.total.toStringAsFixed(2)}',
              emphasize: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onNewRequest,
                child: const Text('Novo pedido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
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
