import '../../core/errors/app_exception.dart';
import '../../core/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../services/checkout_api.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  const CheckoutRepositoryImpl(this._api);

  final CheckoutApi _api;

  @override
  Future<Result<void>> checkout(Cart cart) async {
    try {
      await _api.finalizePurchase(cart);
      return const Success<void>(null);
    } on AppException catch (error) {
      return Failure<void>(error);
    } catch (_) {
      return const Failure<void>(
        AppException(
          'Um erro inesperado ocorreu ao finalizar a compra.',
        ),
      );
    }
  }
}
