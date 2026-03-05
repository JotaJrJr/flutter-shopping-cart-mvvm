class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.price,
    required this.rating,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final double price;
  final ProductRating rating;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'price': price,
      'rating': rating.toMap(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      imageUrl: map['imageUrl'] as String,
      price: (map['price'] as num).toDouble(),
      rating: ProductRating.fromMap(map['rating'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Product &&
            runtimeType == other.runtimeType &&
            id == other.id);
  }

  @override
  int get hashCode => id.hashCode;
}

class ProductRating {
  const ProductRating({required this.rate, required this.count});

  final double rate;
  final double count;

  Map<String, dynamic> toMap() {
    return {
      'rate': rate,
      'count': count,
    };
  }

  factory ProductRating.fromMap(Map<String, dynamic> map) {
    return ProductRating(
      rate: (map['rate'] as num).toDouble(),
      count: (map['count'] as num).toDouble(),
    );
  }
}
