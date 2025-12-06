import '../models/product.dart';

abstract class ProductService {
  Future<Product?> fetchByBarcode(String barcode);
}

// demo/mock implementation
class MockProductService implements ProductService {
  @override
  Future<Product?> fetchByBarcode(String barcode) async {
    await Future.delayed(Duration(milliseconds: 400));
    // return demo product for any barcode
    return Product.demo();
  }
}
