import '../../core/result.dart';
import '../entities/cart.dart';

abstract class CheckoutRepository {
  Future<Result<void>> checkout(Cart cart);
}
