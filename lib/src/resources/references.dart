import '../http_client.dart';

/// References resource for reference data (banks, currencies, countries).
class References {
  /// Creates a new [References] resource.
  References(this._http);

  final MalipopayHttpClient _http;

  /// List supported banks.
  Future<dynamic> banks() {
    return _http.get('/api/v1/standard/banks');
  }

  /// List supported financial institutions.
  Future<dynamic> institutions() {
    return _http.get('/api/v1/standard/institutions');
  }

  /// List supported currencies.
  Future<dynamic> currencies() {
    return _http.get('/api/v1/standard/currency');
  }

  /// List supported countries.
  Future<dynamic> countries() {
    return _http.get('/api/v1/standard/countries');
  }

  /// List business types.
  Future<dynamic> businessTypes() {
    return _http.get('/api/v1/standard/businessType');
  }

  /// List organizational types.
  Future<dynamic> organizationalTypes() {
    return _http.get('/api/v1/standard/organizationalType');
  }
}
