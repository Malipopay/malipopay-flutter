import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:malipopay/malipopay.dart';
import 'package:test/test.dart';

const secret = 'whsec_test_secret_123';

String sign(String payload, String secret) {
  final digest =
      Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload));
  return 'sha256=$digest';
}

void main() {
  group('Webhooks', () {
    final webhooks = Webhooks(secret: secret);

    group('verify', () {
      test('returns true for valid signature', () {
        const payload = '{"type":"payment.completed","data":{"reference":"PAY-123"}}';
        final signature = sign(payload, secret);
        expect(webhooks.verify(payload, signature), isTrue);
      });

      test('returns false for invalid signature', () {
        const payload = '{"type":"payment.completed"}';
        final signature = sign(payload, 'wrong-secret');
        expect(webhooks.verify(payload, signature), isFalse);
      });

      test('handles signature without sha256= prefix', () {
        const payload = '{"type":"payment.completed"}';
        final digest =
            Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload));
        expect(webhooks.verify(payload, digest.toString()), isTrue);
      });

      test('throws if no secret available', () {
        final noSecret = Webhooks();
        expect(
          () => noSecret.verify('payload', 'sig'),
          throwsA(isA<MalipopayException>()),
        );
      });

      test('accepts secret as method parameter', () {
        final noSecret = Webhooks();
        const payload = '{"type":"test"}';
        final signature = sign(payload, secret);
        expect(noSecret.verify(payload, signature, secret: secret), isTrue);
      });
    });

    group('constructEvent', () {
      test('parses valid webhook payload', () {
        const payload =
            '{"type":"payment.completed","data":{"reference":"PAY-123","amount":10000},"timestamp":"2026-04-12T10:00:00Z"}';
        final signature = sign(payload, secret);
        final event = webhooks.constructEvent(payload, signature);

        expect(event.type, equals('payment.completed'));
        expect(event.data['reference'], equals('PAY-123'));
        expect(event.data['amount'], equals(10000));
        expect(event.timestamp, equals('2026-04-12T10:00:00Z'));
      });

      test('throws on invalid signature', () {
        const payload = '{"type":"payment.completed"}';
        expect(
          () => webhooks.constructEvent(payload, 'invalid-sig'),
          throwsA(isA<MalipopayException>()),
        );
      });
    });

    group('sign (static)', () {
      test('produces a valid signature', () {
        const payload = '{"test":true}';
        final sig = Webhooks.sign(payload, secret);
        expect(sig, startsWith('sha256='));
        expect(webhooks.verify(payload, sig), isTrue);
      });
    });
  });
}
