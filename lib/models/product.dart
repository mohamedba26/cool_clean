class Product {
  final String code;
  final String name;
  final String brand;
  final String imageUrl;
  final String ingredients;
  final bool boycott;
  final String origin;
  final String nutriScore;
  final List<String> additives;

  Product({
    required this.code,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.ingredients,
    required this.boycott,
    required this.origin,
    required this.nutriScore,
    required this.additives,
  });

  factory Product.fromOpenFoodFactsJson(Map<String, dynamic> json) {
    final p = json['product'] ?? {};
    return Product(
      code: p['code'] ?? '',
      name: p['product_name'] ?? 'Unknown product',
      brand: (p['brands'] ?? '').toString(),
      imageUrl: p['image_front_small_url'] ?? '',
      ingredients: p['ingredients_text'] ?? '',
      nutriScore: (p['nutriscore_grade'] ?? '').toString().toUpperCase(),
      origin: (p['countries'] ?? 'Unknown').toString(),
      additives:
          (p['additives_tags'] as List<dynamic>?)
              ?.map((e) => e.toString().replaceAll('en:', '').toLowerCase())
              .toList() ??
          [],
      boycott: _isBrandBoycotted((p['brands'] ?? '').toString()),
    );
  }

  // demo fallback for UI testing
  factory Product.demo() {
    return Product(
      code: '5449000054227',
      name: 'Coca Cola (demo)',
      brand: 'Coca Cola',
      imageUrl: '',
      ingredients: 'Eau, sucre, colorant E150d, arôme',
      boycott: true,
      origin: 'USA',
      nutriScore: 'E',
      additives: ['e150d'],
    );
  }

  static bool _isBrandBoycotted(String brand) {
    final boycottBrands = ['coca cola', 'nestlé', 'pepsi', 'starbucks', 'puma'];
    final low = brand.toLowerCase();
    return boycottBrands.any((b) => low.contains(b));
  }
}
