import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'exceptions.dart';

/// A parsed webhook event.
class WebhookEvent {
  /// Creates a new [WebhookEvent].
  WebhookEvent({
    required this.type,
    required this.data,
    required this.timestamp,
    this.reference,
  });

  /// Event type, e.g. `payment.completed`.
  final String type;

  /// Event payload data.
  final Map<String, dynamic> data;

  /// ISO 8601 timestamp.
  final String timestamp;

  /// Optional reference this event relates to.
  final String? reference;

  /// Parses a JSON payload into a [WebhookEvent].
  factory WebhookEvent.fromJson(Map<String, dynamic> json) {
    return WebhookEvent(
      type: json['type'] as String,
      data: (json['data'] as Map<String, dynamic>? ?? {}),
      timestamp: json['timestamp'] as String? ?? '',
      reference: json['reference'] as String?,
    );
  }
}

/// Webhook event type constants.
abstract class WebhookEventType {
  /// Payment initiated.
  static const paymentInitiated = 'payment.initiated';

  /// Payment completed.
  static const paymentCompleted = 'payment.completed';

  /// Payment failed.
  static const paymentFailed = 'payment.failed';

  /// Payment reversed.
  static const paymentReversed = 'payment.reversed';

  /// Collection completed.
  static const collectionCompleted = 'collection.completed';

  /// Collection failed.
  static const collectionFailed = 'collection.failed';

  /// Disbursement completed.
  static const disbursementCompleted = 'disbursement.completed';

  /// Disbursement failed.
  static const disbursementFailed = 'disbursement.failed';

  /// Invoice paid.
  static const invoicePaid = 'invoice.paid';

  /// Invoice overdue.
  static const invoiceOverdue = 'invoice.overdue';
}

/// Webhook signature verification and event parsing.
class Webhooks {
  /// Creates a new [Webhooks] instance.
  Webhooks({this.secret});

  /// Secret used for signature verification. May be overridden per-call.
  final String? secret;

  /// Verify an HMAC-SHA256 webhook signature.
  ///
  /// Returns `true` if the [signature] matches the expected HMAC of [payload].
  bool verify(String payload, String signature, {String? secret}) {
    final key = secret ?? this.secret;
    if (key == null) {
      throw MalipopayException(
          'Webhook secret is required. Pass it to the Webhooks constructor or to verify().');
    }

    final expected =
        Hmac(sha256, utf8.encode(key)).convert(utf8.encode(payload)).toString();

    final sig =
        signature.startsWith('sha256=') ? signature.substring(7) : signature;

    return _timingSafeEqual(expected, sig);
  }

  /// Verify and parse a webhook payload into a [WebhookEvent].
  ///
  /// Throws [MalipopayException] if the signature is invalid or the payload is malformed.
  WebhookEvent constructEvent(String payload, String signature,
      {String? secret}) {
    if (!verify(payload, signature, secret: secret)) {
      throw MalipopayException('Webhook signature verification failed');
    }

    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      return WebhookEvent.fromJson(decoded);
    } catch (e) {
      throw MalipopayException('Invalid webhook payload: not valid JSON');
    }
  }

  /// Static helper to sign a payload with a secret.
  static String sign(String payload, String secret) {
    final digest =
        Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload));
    return 'sha256=$digest';
  }

  bool _timingSafeEqual(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
