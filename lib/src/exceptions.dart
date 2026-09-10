/// Base exception thrown by the Malipopay SDK.
class MalipopayException implements Exception {
  /// Creates a new [MalipopayException].
  MalipopayException(
    this.message, {
    this.statusCode,
    this.code,
    this.details,
  });

  /// Human-readable error message.
  final String message;

  /// HTTP status code from the API (if applicable).
  final int? statusCode;

  /// Malipopay-specific error code.
  final int? code;

  /// Additional error details.
  final String? details;

  @override
  String toString() => 'MalipopayException: $message';
}

/// Thrown when the API key is invalid or missing (HTTP 401).
class AuthenticationException extends MalipopayException {
  /// Creates an [AuthenticationException].
  AuthenticationException([super.message = 'Invalid API key'])
      : super(statusCode: 401);
}

/// Thrown when the API key lacks permission (HTTP 403).
class PermissionException extends MalipopayException {
  /// Creates a [PermissionException].
  PermissionException([super.message = 'Insufficient permissions'])
      : super(statusCode: 403);
}

/// Thrown when a resource is not found (HTTP 404).
class NotFoundException extends MalipopayException {
  /// Creates a [NotFoundException].
  NotFoundException([super.message = 'Resource not found'])
      : super(statusCode: 404);
}

/// Thrown when request validation fails (HTTP 422).
class ValidationException extends MalipopayException {
  /// Creates a [ValidationException].
  ValidationException(super.message, {this.fields}) : super(statusCode: 422);

  /// Field-level validation errors.
  final Map<String, String>? fields;
}

/// Thrown when rate limit is exceeded (HTTP 429).
class RateLimitException extends MalipopayException {
  /// Creates a [RateLimitException].
  RateLimitException([super.message = 'Rate limit exceeded', this.retryAfter])
      : super(statusCode: 429);

  /// Seconds to wait before retrying.
  final int? retryAfter;
}

/// Thrown for 5xx server errors.
class ApiException extends MalipopayException {
  /// Creates an [ApiException].
  ApiException(super.message, int statusCode, {super.code})
      : super(statusCode: statusCode);
}

/// Thrown for network/connection errors.
class ConnectionException extends MalipopayException {
  /// Creates a [ConnectionException].
  ConnectionException([super.message = 'Connection failed']);
}
