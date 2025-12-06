import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class OpenFoodFactsService {
  static const _base = 'https://world.openfoodfacts.org/api/v2/product';

  Future<Product?> fetchByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_base/$barcode.json');
      final resp = await http.get(url).timeout(Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['status'] == 1) {
          return Product.fromOpenFoodFactsJson(data);
        }
      }
    } catch (e) {
      print('OpenFoodFacts error: $e');
    }
    return null;
  }

  /// Search by textual query (used when image-label returns a label)
  Future<Product?> searchByName(String query) async {
    try {
      final q = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$q&search_simple=1&action=process&json=1&page_size=1',
      );
      final resp = await http.get(url).timeout(Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final products = data['products'] as List<dynamic>?;
        if (products != null && products.isNotEmpty) {
          // convert to OpenFoodFacts v2-like format expected by Product.fromOpenFoodFactsJson
          final fake = {'status': 1, 'product': products.first};
          return Product.fromOpenFoodFactsJson(fake);
        }
      }
    } catch (e) {
      print('search error: $e');
    }
    return null;
  }
}
