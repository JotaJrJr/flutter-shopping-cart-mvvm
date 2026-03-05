import '../../core/errors/app_exception.dart';
import '../../core/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_sync_repository.dart';
import '../services/cart_api.dart';

class CartSyncRepositoryImpl implements CartSyncRepository {
  const CartSyncRepositoryImpl(this._api);

  final CartApi _api;

  @override
  Future<Result<void>> syncCart(Cart cart) async {
    try {
      await _api.syncCart(cart);
      return const Success<void>(null);
    } on AppException catch (error) {
      return Failure<void>(error);
    } catch (_) {
      return const Failure<void>(
        AppException('Um erro inesperado ocorreu ao sincronizar o carrinho.'),
      );
    }
  }
}
