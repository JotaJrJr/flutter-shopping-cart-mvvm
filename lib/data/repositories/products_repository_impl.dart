import '../../core/errors/app_exception.dart';
import '../../core/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../services/products_api.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl(this._api);

  final ProductsApi _api;

  @override
  Future<Result<List<Product>>> loadProducts() async {
    try {
      final dtos = await _api.fetchProducts();
      return Success<List<Product>>(
        dtos.map((item) => item.toEntity()).toList(),
      );
    } on AppException catch (error) {
      return Failure<List<Product>>(error);
    } catch (_) {
      return const Failure<List<Product>>(
        AppException('Um erro inesperado ocorreu ao carregar os produtos.'),
      );
    }
  }
}
