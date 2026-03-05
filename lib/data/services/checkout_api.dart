import 'dart:math';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/cart.dart';

class CheckoutApi {
  final Random _random = Random();

  Future<void> finalizePurchase(Cart cart) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (cart.isEmpty) {
      throw const AppException('Não é possível finalizar a compra com um carrinho vazio.');
    }

    if (_random.nextInt(100) < 20) {
      throw const AppException('Falha na finalização da compra. Tente novamente.');
    }
  }
}
