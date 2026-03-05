import '../../domain/entities/product.dart';

class ProductDto {
  const ProductDto({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.image,
    required this.price,
    required this.ratingRate,
    required this.ratingCount,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String image;
  final double price;
  final double ratingRate;
  final double ratingCount;

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as Map<String, dynamic>;

    return ProductDto(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      price: (json['price'] as num).toDouble(),
      ratingRate: (rating['rate'] as num).toDouble(),
      ratingCount: (rating['count'] as num).toDouble(),
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      title: title,
      description: description,
      category: category,
      imageUrl: image,
      price: price,
      rating: ProductRating(rate: ratingRate, count: ratingCount),
    );
  }
}
