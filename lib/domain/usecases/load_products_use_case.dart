import '../../core/result.dart';
import '../entities/product.dart';
import '../repositories/products_repository.dart';

class LoadProductsUseCase {
  const LoadProductsUseCase(this._repository);

  final ProductsRepository _repository;

  Future<Result<List<Product>>> execute() => _repository.loadProducts();
}
