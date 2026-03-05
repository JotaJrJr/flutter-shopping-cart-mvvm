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
}
