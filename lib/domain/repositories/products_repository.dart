import '../../core/result.dart';
import '../entities/product.dart';

abstract class ProductsRepository {
  Future<Result<List<Product>>> loadProducts();
}
