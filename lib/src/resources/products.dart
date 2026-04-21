import '../http_client.dart';

/// Products resource for managing product catalog.
class Products {
  /// Creates a new [Products] resource.
  Products(this._http);

  final MalipopayHttpClient _http;

  /// Create a new product.
  Future<dynamic> create(Map<String, dynamic> params) {
    return _http.post('/api/v1/product', body: params);
  }

  /// List all products.
  Future<dynamic> list({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/product', params: params);
  }

  /// Get a product by ID.
  Future<dynamic> get(String productId) {
    return _http.get('/api/v1/product/${Uri.encodeComponent(productId)}');
  }

  /// Get a product by product number.
  Future<dynamic> getByNumber(String productNo) {
    return _http
        .get('/api/v1/product/product/${Uri.encodeComponent(productNo)}');
  }

  /// Update a product.
  Future<dynamic> update(Map<String, dynamic> params) {
    return _http.put('/api/v1/product', body: params);
  }
}
