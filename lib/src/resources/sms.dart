import '../http_client.dart';

/// SMS resource for sending single, bulk, and scheduled SMS.
class Sms {
  /// Creates a new [Sms] resource.
  Sms(this._http);

  final MalipopayHttpClient _http;

  /// Send a single SMS.
  ///
  /// Required fields: `sender`, `phoneNumber`, `message`.
  Future<dynamic> send(Map<String, dynamic> params) {
    return _http.post('/sms/', body: params);
  }

  /// Send bulk SMS to multiple recipients.
  ///
  /// Required fields: `sender`, `phoneNumber` (list), `message`.
  Future<dynamic> sendBulk(Map<String, dynamic> params) {
    return _http.post('/sms/bulk', body: params);
  }

  /// Schedule an SMS for future delivery.
  ///
  /// Required fields: `sender`, `phoneNumber` (list), `message`, `date` (ISO 8601).
  Future<dynamic> schedule(Map<String, dynamic> params) {
    return _http.post('/sms/schedule', body: params);
  }

  /// List SMS logs.
  Future<dynamic> list({Map<String, dynamic>? params}) {
    return _http.get('/sms/', params: params);
  }

  /// Get a single SMS log by ID.
  Future<dynamic> get(String id) {
    return _http.get('/sms/${Uri.encodeComponent(id)}');
  }

  /// Search SMS logs.
  Future<dynamic> search(Map<String, dynamic> params) {
    return _http.get('/sms/search', params: params);
  }
}
