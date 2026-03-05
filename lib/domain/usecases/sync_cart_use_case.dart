import '../../core/result.dart';
import '../entities/cart.dart';
import '../repositories/cart_sync_repository.dart';

class SyncCartUseCase {
  const SyncCartUseCase(this._repository);

  final CartSyncRepository _repository;

  Future<Result<void>> execute(Cart cart) => _repository.syncCart(cart);
}
