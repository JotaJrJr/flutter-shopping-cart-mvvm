import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../core/errors/app_exception.dart';
import '../dtos/product_dto.dart';

class ProductsApi {
  static const String _productsUrl = 'https://fakestoreapi.com/products';

  final Random _random = Random();

  Future<List<ProductDto>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _throwRandomFailure('Não foi possível carregar os produtos. Tente novamente.');

    final client = HttpClient();

    try {
      final request = await client.getUrl(Uri.parse(_productsUrl));
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw AppException('Produtos: ${response.statusCode}.');
      }

      final raw = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .map((item) => ProductDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on AppException {
      rethrow;
    } on SocketException {
      throw const AppException(
        'Não foi possível acessar a API de produtos. Verifique sua conexão e tente novamente.',
      );
    } on HttpException {
      throw const AppException('Resposta inválida da API de produtos.');
    } catch (_) {
      throw const AppException(
        'Um erro inesperado ocorreu ao carregar os produtos.',
      );
    } finally {
      client.close(force: true);
    }
  }

  void _throwRandomFailure(String message) {
    if (_random.nextInt(100) < 25) {
      throw AppException(message);
    }
  }
}
