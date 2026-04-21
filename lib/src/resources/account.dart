import '../http_client.dart';

/// Account resource for account transactions, reconciliation, and reports.
class Account {
  /// Creates a new [Account] resource.
  Account(this._http);

  final MalipopayHttpClient _http;

  /// Get all account transactions.
  Future<dynamic> transactions({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/account/allTransaction', params: params);
  }

  /// Search account transactions.
  Future<dynamic> searchTransactions(Map<String, dynamic> params) {
    return _http.get('/api/v1/account/transaction/search', params: params);
  }

  /// Get a single account transaction by ID.
  Future<dynamic> getTransaction(String id) {
    return _http
        .get('/api/v1/account/transaction/${Uri.encodeComponent(id)}');
  }

  /// List reconciliation webhooks.
  Future<dynamic> reconciliation({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/account/reconciliation', params: params);
  }

  /// Search reconciliation webhooks.
  Future<dynamic> searchReconciliation(Map<String, dynamic> params) {
    return _http.get('/api/v1/account/reconciliation/search', params: params);
  }

  /// Get a reconciliation webhook by reference.
  Future<dynamic> getReconciliation(String reference) {
    return _http.get(
        '/api/v1/account/reconciliation/${Uri.encodeComponent(reference)}');
  }

  /// Generate the financial position report.
  Future<dynamic> financialPosition({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/account/financialPosition', params: params);
  }

  /// Generate the income statement.
  Future<dynamic> incomeStatement({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/account/incomeStatement', params: params);
  }

  /// Generate the general ledger.
  Future<dynamic> generalLedger({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/account/generalLedger', params: params);
  }

  /// Generate the trial balance.
  Future<dynamic> trialBalance({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/account/trialBalance', params: params);
  }
}
