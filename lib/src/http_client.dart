import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';

/// Internal HTTP client wrapping the Malipopay API.
class MalipopayHttpClient {
  /// Creates a new [MalipopayHttpClient].
  MalipopayHttpClient({
    required this.baseUrl,
    required this.apiKey,
    this.timeout = const Duration(seconds: 30),
    this.retries = 2,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  /// The base URL for the API.
  final String baseUrl;

  /// The API key used for authentication.
  final String apiKey;

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
      'apiToken': apiKey,
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

      if (_isRetryable(response.statusCode) && attempt < retries) {
        await Future<void>.delayed(_backoff(attempt));
        return _request(method, path,
            params: params, body: body, attempt: attempt + 1);
      }

      throw _errorFromResponse(response);
    } on TimeoutException {
      if (attempt < retries) {
        await Future<void>.delayed(_backoff(attempt));
        return _request(method, path,
            params: params, body: body, attempt: attempt + 1);
      }
      throw ConnectionException('Request timed out after $timeout');
    } on MalipopayException {
      rethrow;
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

    final message = (body['message'] as String?) ?? response.reasonPhrase ?? 'Unknown error';
    final code = body['code'] as int?;

    switch (response.statusCode) {
      case 401:
        return AuthenticationException(message);
      case 403:
        return PermissionException(message);
      case 404:
        return NotFoundException(message);
      case 422:
        return ValidationException(message);
      case 429:
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
        return RateLimitException(message, retryAfter);
      default:
        return ApiException(message, response.statusCode, code: code);
    }
  }
}
