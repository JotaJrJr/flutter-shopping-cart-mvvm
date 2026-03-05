import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../domain/entities/cart.dart';
import '../stores/cart_store.dart';

class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({
    super.key,
    required this.cartStore,
    this.enabled = true,
  });

  final CartStore cartStore;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Cart>(
      valueListenable: cartStore.cart,
      builder: (context, cart, child) {
        final badgeVisible = cart.totalItems > 0;

        return IconButton(
          onPressed: enabled
              ? () => Navigator.of(context).pushNamed(AppRoutes.cart)
              : null,
          icon: Badge(
            isLabelVisible: badgeVisible,
            label: Text('${cart.totalItems}'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }
}
