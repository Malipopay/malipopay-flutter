import '../http_client.dart';

/// Customers resource for managing customer records.
class Customers {
  /// Creates a new [Customers] resource.
  Customers(this._http);

  final MalipopayHttpClient _http;

  /// Create a new customer.
  Future<dynamic> create(Map<String, dynamic> params) {
    return _http.post('/api/v1/customer', body: params);
  }

  /// List all customers.
  Future<dynamic> list({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/customer', params: params);
  }

  /// Get a customer by ID.
  Future<dynamic> get(String customerId) {
    return _http.get('/api/v1/customer/${Uri.encodeComponent(customerId)}');
  }

  /// Get a customer by customer number.
  Future<dynamic> getByNumber(String customerNo) {
    return _http
        .get('/api/v1/customer/number/${Uri.encodeComponent(customerNo)}');
  }

  /// Get a customer by phone number.
  Future<dynamic> getByPhone(String phoneNumber) {
    return _http.get(
        '/api/v1/customer/phoneNumber/${Uri.encodeComponent(phoneNumber)}');
  }

  /// Search customers.
  Future<dynamic> search(Map<String, dynamic> params) {
    return _http.get('/api/v1/customer/search', params: params);
  }

  /// Verify a customer by phone number.
  Future<dynamic> verify(String phoneNumber) {
    return _http
        .post('/api/v1/customer/verify', body: {'phoneNumber': phoneNumber});
  }
}
