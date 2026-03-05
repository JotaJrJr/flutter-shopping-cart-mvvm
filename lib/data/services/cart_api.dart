import 'dart:math';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/cart.dart';

class CartApi {
  final Random _random = Random();

  Future<void> syncCart(Cart cart) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (cart.totalDistinctItems > 10) {
      throw const AppException('O carrinho não pode ter mais de 10 produtos distintos.');
    }

    if (_random.nextInt(100) < 5) {
      throw const AppException('Falha na sincronização do carrinho. Tente novamente.');
    }
  }
}
