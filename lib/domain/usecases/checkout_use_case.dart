import '../../core/result.dart';
import '../entities/cart.dart';
import '../repositories/checkout_repository.dart';

class CheckoutUseCase {
  const CheckoutUseCase(this._repository);

  final CheckoutRepository _repository;

  Future<Result<void>> execute(Cart cart) => _repository.checkout(cart);
}
