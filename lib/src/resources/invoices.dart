import '../http_client.dart';

/// Invoices resource for creating, listing, and managing invoices.
class Invoices {
  /// Creates a new [Invoices] resource.
  Invoices(this._http);

  final MalipopayHttpClient _http;

  /// Create a new invoice.
  Future<dynamic> create(Map<String, dynamic> params) {
    return _http.post('/api/v1/invoice', body: params);
  }

  /// List all invoices.
  Future<dynamic> list({Map<String, dynamic>? params}) {
    return _http.get('/api/v1/invoice', params: params);
  }

  /// Get an invoice by ID.
  Future<dynamic> get(String invoiceId) {
    return _http.get('/api/v1/invoice/${Uri.encodeComponent(invoiceId)}');
  }

  /// Get an invoice by invoice number.
  Future<dynamic> getByNumber(String invoiceNo) {
    return _http
        .get('/api/v1/invoice/invoice/${Uri.encodeComponent(invoiceNo)}');
  }

  /// Update an invoice.
  Future<dynamic> update(String invoiceId, Map<String, dynamic> params) {
    return _http.put('/api/v1/invoice/${Uri.encodeComponent(invoiceId)}',
        body: params);
  }

  /// Record a payment against an invoice.
  Future<dynamic> recordPayment(Map<String, dynamic> params) {
    return _http.post('/api/v1/invoice/record-payment', body: params);
  }

  /// Approve a draft invoice.
  Future<dynamic> approveDraft(Map<String, dynamic> params) {
    return _http.post('/api/v1/invoice/approve-draft', body: params);
  }

  /// Get the next invoice number.
  Future<dynamic> nextInvoiceNo() {
    return _http.get('/api/v1/invoice/next-invoice-no');
  }

  /// Get the invoice dashboard summary.
  Future<dynamic> dashboard() {
    return _http.get('/api/v1/invoice/dashboard');
  }
}
