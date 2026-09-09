import '../http_client.dart';

/// Payments resource. Handles collections, disbursements, payment links, and verification.
class Payments {
  /// Creates a new [Payments] resource.
  Payments(this._http);

  final MalipopayHttpClient _http;

  /// Initiate a generic payment intent.
  ///
  /// [mode] - "PAYOUT", "CHARGE", or "REFUND"
  Future<dynamic> initiate(Map<String, dynamic> params) {
    return _http.post('/api/v1/payment', body: params);
  }

  /// Collect a mobile money payment from a customer.
  ///
  /// Required: [description], [amount], [phoneNumber].
  Future<dynamic> collect(Map<String, dynamic> params) {
    return _http.post('/api/v1/payment/collection', body: params);
  }

  /// Send money to a recipient (disbursement).
  Future<dynamic> disburse(Map<String, dynamic> params) {
    return _http.post('/api/v1/payment/disbursement', body: params);
  }

  /// Execute an immediate payment against an existing reference.
  Future<dynamic> payNow(Map<String, dynamic> params) {
    return _http.post('/api/v1/payment/now', body: params);
  }

  /// Verify the status of a payment by reference.
  Future<dynamic> verify(String reference) {
    return _http
        .get('/api/v1/payment/verify/${Uri.encodeComponent(reference)}');
  }

  /// Get a payment by reference.
  Future<dynamic> get(String reference) {
    return _http
        .get('/api/v1/payment/reference/${Uri.encodeComponent(reference)}');
  }

  /// List all payments.
  Future<dynamic> list({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/payment', params: params);
  }

  /// Search payments with filters.
  Future<dynamic> search(Map<String, dynamic> params) {
    return _http.get('/api/v1/payment/search', params: params);
  }

  /// Approve a payment (for workflows requiring approval).
  Future<dynamic> approve(Map<String, dynamic> params) {
    return _http.post('/api/v1/payment/approve', body: params);
  }

  /// Confirm a payment approval.
  Future<dynamic> confirmApproval(Map<String, dynamic> params) {
    return _http.post('/api/v1/payment/approve/confirm', body: params);
  }

  /// Retry a failed collection.
  Future<dynamic> retry(String reference) {
    return _http.get('/api/v1/payment/retry/${Uri.encodeComponent(reference)}');
  }

  /// Create a payment link.
  Future<dynamic> createLink(Map<String, dynamic> params) {
    return _http.post('/api/v1/payment/link', body: params);
  }

  /// Get the payment dashboard summary.
  Future<dynamic> dashboard() {
    return _http.get('/api/v1/payment/dashboard');
  }
}
