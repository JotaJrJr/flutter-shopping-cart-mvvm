import '../../core/result.dart';
import '../entities/cart.dart';

abstract class CartSyncRepository {
  Future<Result<void>> syncCart(Cart cart);
}
