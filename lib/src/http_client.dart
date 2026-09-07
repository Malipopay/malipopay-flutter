import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth.dart';
import 'exceptions.dart';

/// Internal HTTP client wrapping the Malipopay API.
class MalipopayHttpClient {
  /// Creates a new [MalipopayHttpClient].
  MalipopayHttpClient({
    required this.baseUrl,
    required this.auth,
    this.timeout = const Duration(seconds: 30),
    this.retries = 2,
    this.onUnauthorized,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  /// The base URL for the API.
  final String baseUrl;

  /// How this client proves who it is. See [MalipopayAuth].
  final MalipopayAuth auth;

  /// Called when the API rejects the credentials (HTTP 401).
  ///
  /// A session-authenticated app uses this to refresh or to sign the user out.
  /// It fires before the exception is thrown, and does not retry the request.
  final Future<void> Function()? onUnauthorized;

  /// Request timeout.
  final Duration timeout;

  /// Number of retries for transient errors.
  final int retries;

  final http.Client _client;

  /// Closes the underlying HTTP client.
  void close() => _client.close();

  /// Performs a GET request.
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) {
    return _request('GET', path, params: params);
  }

  /// Performs a POST request.
  Future<dynamic> post(String path, {Object? body}) {
    return _request('POST', path, body: body);
  }

  /// Performs a PUT request.
  Future<dynamic> put(String path, {Object? body}) {
    return _request('PUT', path, body: body);
  }

  /// Performs a DELETE request.
  Future<dynamic> delete(String path) {
    return _request('DELETE', path);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? params,
    Object? body,
    int attempt = 0,
  }) async {
    final uri = _buildUri(path, params);
    final headers = <String, String>{
      ...await auth.headers(path),
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };

    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      late http.Response response;
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(timeout);
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
        case 'DELETE':
          response =
              await _client.delete(uri, headers: headers).timeout(timeout);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      }

      if (response.statusCode == 401) {
        await onUnauthorized?.call();
      }

      if (_isRetryable(response.statusCode) &&
          _isSafeToRetry(method) &&
          attempt < retries) {
        await Future<void>.delayed(_backoff(attempt));
        return await _request(method, path,
            params: params, body: body, attempt: attempt + 1);
      }

      throw _errorFromResponse(response);
    } on TimeoutException {
      if (_isSafeToRetry(method) && attempt < retries) {
        await Future<void>.delayed(_backoff(attempt));
        return await _request(method, path,
            params: params, body: body, attempt: attempt + 1);
      }
      throw ConnectionException('Request timed out after $timeout');
    } on MalipopayException {
      rethrow;
    } on FormatException catch (e) {
      // The connection was fine; the server sent something unparseable.
      // Reporting this as a connection error sends the caller to retry logic
      // that cannot help.
      throw ApiException('Malformed response from the API: ${e.message}', 0);
    } catch (e) {
      throw ConnectionException(e.toString());
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? params) {
    final uri = Uri.parse('$baseUrl$path');
    if (params == null || params.isEmpty) return uri;
    final queryParams = <String, String>{};
    for (final entry in params.entries) {
      if (entry.value != null) {
        queryParams[entry.key] = entry.value.toString();
      }
    }
    return uri.replace(queryParameters: queryParams);
  }

  bool _isRetryable(int statusCode) => statusCode == 429 || statusCode >= 500;

  /// Whether repeating this request can only be harmless.
  ///
  /// GET, PUT and DELETE are idempotent by definition. POST is not, and there
  /// is currently no way to make it so.
  ///
  /// A retried `/payment/collection` or `/payment/disbursement` whose first
  /// attempt actually reached the backend charges or pays out twice, and a
  /// timeout cannot tell you which side of the wire it failed on.
  ///
  /// An earlier version of this made an exception for a POST carrying a
  /// caller-supplied `reference`, on the belief that the backend treated it
  /// as an idempotency key. **It does not.** Measured against UAT on
  /// 2026-09-07: two `POST /api/v2/payment/collection` calls with the
  /// identical `reference` of `MRCH629732` produced two separate payments,
  /// `MU00206` and `MU00207`, with different ids and both charging 1,000 TZS.
  /// The caller's value is stored as `customerReference`, a label, while the
  /// payment's own reference is minted server-side.
  ///
  /// So no POST is retried. This matters more than it looks: that same
  /// collection call took 41 seconds on its first attempt, which is longer
  /// than most default client timeouts, so the retry would have fired
  /// routinely rather than rarely.
  ///
  /// Restore the exception only when the backend accepts a real idempotency
  /// key and answers a repeat with the original payment.
  static bool _isSafeToRetry(String method) => method != 'POST';

  Duration _backoff(int attempt) {
    final ms = (1000 * (1 << attempt)).clamp(1000, 10000);
    return Duration(milliseconds: ms);
  }

  MalipopayException _errorFromResponse(http.Response response) {
    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    // Malipopay puts a code label in `message` and the human-readable reason
    // in `details`. Preferring `message` is what makes every failure read as
    // a generic "controller:x:y->error" string.
    final details = _detailsOf(body);
    final message = details ??
        (body['message'] as String?) ??
        response.reasonPhrase ??
        'Unknown error';
    final code = body['code'] is int ? body['code'] as int : null;

    switch (response.statusCode) {
      case 401:
        return AuthenticationException(message);
      case 403:
        return PermissionException(message);
      case 404:
        return NotFoundException(message);
      // 400 as well as 422: central-api returns 400 for most validation
      // failures, and callers need the field map from both.
      case 400:
      case 422:
        return ValidationException(message, fields: _fieldsOf(body));
      case 429:
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
        return RateLimitException(message, retryAfter);
      default:
        return ApiException(message, response.statusCode, code: code);
    }
  }

  /// The human-readable reason, from whichever shape the API used.
  static String? _detailsOf(Map<String, dynamic> body) {
    final d = body['details'] ?? body['detail'] ?? body['error'];
    if (d is String && d.isNotEmpty) return d;
    if (d is List && d.isNotEmpty) {
      return d.map((e) => e.toString()).join(', ');
    }
    return null;
  }

  /// Field-level validation errors, when the API sent any.
  ///
  /// Accepts both `{"field": "reason"}` and `{"field": ["reason", ...]}`.
  static Map<String, String>? _fieldsOf(Map<String, dynamic> body) {
    final raw = body['errors'] ?? body['fields'] ?? body['validation'];
    if (raw is! Map) return null;
    final out = <String, String>{};
    raw.forEach((k, v) {
      out[k.toString()] =
          v is List ? v.map((e) => e.toString()).join(', ') : v.toString();
    });
    return out.isEmpty ? null : out;
  }
}
