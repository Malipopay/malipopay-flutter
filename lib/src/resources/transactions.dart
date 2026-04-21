import '../http_client.dart';

/// Transactions resource for querying transactions.
class Transactions {
  /// Creates a new [Transactions] resource.
  Transactions(this._http);

  final MalipopayHttpClient _http;

  /// List all transactions.
  Future<dynamic> list({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/transactions', params: params);
  }

  /// Get a transaction by ID.
  Future<dynamic> get(String id) {
    return _http.get('/api/v1/transactions/${Uri.encodeComponent(id)}');
  }

  /// Search transactions.
  Future<dynamic> search(Map<String, dynamic> params) {
    return _http.get('/api/v1/transactions/search', params: params);
  }

  /// Get paginated transactions.
  Future<dynamic> paginate({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/transactions/pagination', params: params);
  }

  /// Get tariff information.
  Future<dynamic> tariffs() {
    return _http.get('/api/v1/transactions/tariffs');
  }
}
