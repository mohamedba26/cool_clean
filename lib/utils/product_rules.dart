import 'package:cool_clean/models/product.dart';

const List<String> boycottBrands = [
  "coca-cola",
  "pepsi",
  "nestle",
  "starbucks",
  "mcdonald",
  "kfc",
  "burger king",
  "doritos",
  "lays",
  "pringles",
  "colgate",
  "palmolive",
  "loreal",
  "pantene",
  "intel",
  "hp",
];

const dangerousIngredients = [
  "e621",
  "e951",
  "e150d",
  "high fructose corn syrup",
  "palm oil",
  "sodium benzoate",
  "potassium sorbate",
  "trans fat",
  "aspartame",
  "acesulfame k",
  "gelatin",
];

const healthyIngredients = [
  "vitamin c",
  "vitamin d",
  "fiber",
  "calcium",
  "iron",
  "magnesium",
  "zinc",
  "omega",
];

bool isBoycotted(Product p) {
  final name = (p.name).toLowerCase();
  final brand = (p.brand).toLowerCase();
  final origin = (p.origin).toLowerCase();

  bool match(String s) => boycottBrands.any((b) => s.contains(b));

  return match(name) || match(brand) || match(origin);
}

List<String> getBadIngredients(String ingredientsText) {
  final text = ingredientsText.toLowerCase();
  return dangerousIngredients.where((i) => text.contains(i)).toList();
}

List<String> getGoodIngredients(String ingredientsText) {
  final text = ingredientsText.toLowerCase();
  return healthyIngredients.where((i) => text.contains(i)).toList();
}

String getProductStatus(Product p) {
  if (isBoycotted(p)) return "boycott";

  final bad = getBadIngredients(p.ingredients);
  if (bad.isNotEmpty) return "danger";

  final grade = (p.nutriScore ?? "").toLowerCase();
  if (grade == "a" || grade == "b") return "safe";

  return "okay";
}
