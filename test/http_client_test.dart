import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:malipopay/malipopay.dart';
import 'package:test/test.dart';

/// Captures what the client actually put on the wire.
class _Spy {
  final requests = <http.BaseRequest>[];
  int calls = 0;

  MockClient responding(
    http.Response Function(http.Request request, int attempt) handler,
  ) {
    return MockClient((request) async {
      requests.add(request);
      return handler(request, calls++);
    });
  }

  /// A handler that can take its time, for exercising the timeout arm.
  MockClient respondingSlowly(
    Future<http.Response> Function(http.Request request, int attempt) handler,
  ) {
    return MockClient((request) async {
      requests.add(request);
      return handler(request, calls++);
    });
  }

  http.BaseRequest get last => requests.last;
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

void main() {
  group('auth headers', () {
    test('API token mode sends apiToken and nothing else', () async {
      final spy = _Spy();
      final client = Malipopay(
        'secret-key',
        environment: MalipopayEnvironment.uat,
        httpClient:
            spy.responding((_, __) => _json({'data': <String, dynamic>{}})),
      );

      await client.payments.list();

      expect(spy.last.headers['apiToken'], 'secret-key');
      expect(spy.last.headers.containsKey('Authorization'), isFalse);
      expect(spy.last.headers.containsKey('project'), isFalse);
    });

    test('session mode sends bearer and project, never apiToken', () async {
      final spy = _Spy();
      final client = Malipopay.session(
        SessionAuth(
          token: () async => 'jwt-abc',
          projectId: () => 'proj-123',
        ),
        environment: MalipopayEnvironment.uat,
        httpClient:
            spy.responding((_, __) => _json({'data': <String, dynamic>{}})),
      );

      await client.payments.list();

      expect(spy.last.headers['Authorization'], 'Bearer jwt-abc');
      expect(spy.last.headers['project'], 'proj-123');
      // The backend branches on apiToken first: sending both would silently
      // discard the JWT and act as the whole project.
      expect(spy.last.headers.containsKey('apiToken'), isFalse);
    });

    test('messaging paths carry the slug, not the project id', () async {
      final spy = _Spy();
      final client = Malipopay.session(
        SessionAuth(
          token: () async => 'jwt-abc',
          projectId: () => 'proj-123',
          projectSlug: () => 'duka-la-asha',
        ),
        environment: MalipopayEnvironment.uat,
        httpClient: spy.responding((_, __) => _json({'data': <dynamic>[]})),
      );

      await client.sms.list();

      expect(spy.last.headers['project'], 'duka-la-asha');
    });

    test('a signed-out session sends no Authorization header', () async {
      final spy = _Spy();
      final client = Malipopay.session(
        SessionAuth(token: () async => null, projectId: () => null),
        environment: MalipopayEnvironment.uat,
        httpClient:
            spy.responding((_, __) => _json({'data': <String, dynamic>{}})),
      );

      await client.payments.list();

      expect(spy.last.headers.containsKey('Authorization'), isFalse);
      expect(spy.last.headers.containsKey('project'), isFalse);
    });

    test('SessionAuth.needsSlug matches with or without a version prefix', () {
      expect(SessionAuth.needsSlug('/sms/'), isTrue);
      expect(SessionAuth.needsSlug('/api/v1/company/buy-credits'), isTrue);
      expect(SessionAuth.needsSlug('/api/v1/waba/templates'), isTrue);
      expect(SessionAuth.needsSlug('/api/v1/payment/collection'), isFalse);
      expect(SessionAuth.needsSlug('/api/v2/payment'), isFalse);
      // A path that merely starts with the same letters is not a match.
      expect(SessionAuth.needsSlug('/api/v1/companies'), isFalse);
    });
  });

  group('retries', () {
    test('a GET is retried on 500', () async {
      final spy = _Spy();
      final client = Malipopay(
        'k',
        environment: MalipopayEnvironment.uat,
        retries: 1,
        httpClient: spy.responding(
          (_, attempt) => attempt == 0
              ? _json({'message': 'boom'}, 500)
              : _json({'data': <String, dynamic>{}}),
        ),
      );

      await client.payments.list();

      expect(spy.requests, hasLength(2));
    });

    test('a POST is NOT retried', () async {
      // The whole point: a collection that timed out may already have charged
      // the customer, and nothing in the response can tell us which.
      final spy = _Spy();
      final client = Malipopay(
        'k',
        environment: MalipopayEnvironment.uat,
        retries: 3,
        httpClient: spy.responding((_, __) => _json({'message': 'boom'}, 500)),
      );

      await expectLater(
        client.payments.collect({
          'description': 'Order',
          'amount': 10000,
          'phoneNumber': '255712345678',
        }),
        throwsA(isA<ApiException>()),
      );

      expect(spy.requests, hasLength(1));
    });

    test('a POST carrying a reference is NOT retried either', () async {
      // This is the case that looks safe and is not. The caller's reference
      // is stored as `customerReference`, a label; the payment's own
      // reference is minted server-side and the backend does not resolve a
      // repeat to the first request.
      //
      // Measured against UAT on 2026-09-07: two POST /api/v2/payment/collection
      // calls with the identical reference MRCH629732 produced MU00206 and
      // MU00207, two payments, both for 1,000 TZS.
      final spy = _Spy();
      final client = Malipopay(
        'k',
        environment: MalipopayEnvironment.uat,
        retries: 3,
        httpClient: spy.responding((_, __) => _json({'message': 'boom'}, 500)),
      );

      await expectLater(
        client.payments.collect({
          'reference': 'ORD-1',
          'description': 'Order',
          'amount': 10000,
          'phoneNumber': '255712345678',
        }),
        throwsA(isA<ApiException>()),
      );

      expect(spy.requests, hasLength(1));
    });

    test('a timed-out POST is not retried either', () async {
      // The timeout arm is the one that fires in practice: that same
      // collection took 41 seconds on its first attempt.
      final spy = _Spy();
      final client = Malipopay(
        'k',
        environment: MalipopayEnvironment.uat,
        retries: 3,
        timeout: const Duration(milliseconds: 50),
        httpClient: spy.respondingSlowly((_, __) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return _json({'data': <String, dynamic>{}});
        }),
      );

      await expectLater(
        client.payments.collect({
          'reference': 'ORD-1',
          'description': 'Order',
          'amount': 10000,
          'phoneNumber': '255712345678',
        }),
        throwsA(isA<ConnectionException>()),
      );

      expect(spy.requests, hasLength(1));
    });
  });

  group('errors', () {
    test('401 fires onUnauthorized before throwing', () async {
      var called = 0;
      final spy = _Spy();
      final client = Malipopay.session(
        SessionAuth(token: () async => 'stale', projectId: () => 'p'),
        environment: MalipopayEnvironment.uat,
        onUnauthorized: () async => called++,
        httpClient: spy.responding((_, __) => _json({'message': 'nope'}, 401)),
      );

      await expectLater(
        client.payments.list(),
        throwsA(isA<AuthenticationException>()),
      );
      expect(called, 1);
    });

    test('400 is a ValidationException carrying the field map', () async {
      final spy = _Spy();
      final client = Malipopay(
        'k',
        environment: MalipopayEnvironment.uat,
        httpClient: spy.responding(
          (_, __) => _json({
            'message': 'controller:payment:validate->error',
            'details': 'Amount must be at least 100',
            'errors': {
              'amount': ['too small'],
              'phoneNumber': 'invalid'
            },
          }, 400),
        ),
      );

      await expectLater(
        client.payments.list(),
        throwsA(
          isA<ValidationException>()
              // details wins: `message` is a code label, not something a
              // person can read.
              .having(
                  (e) => e.message, 'message', 'Amount must be at least 100')
              .having((e) => e.fields?['amount'], 'fields.amount', 'too small')
              .having(
                (e) => e.fields?['phoneNumber'],
                'fields.phoneNumber',
                'invalid',
              ),
        ),
      );
    });

    test('a 500 with only a message still reads that message', () async {
      final spy = _Spy();
      final client = Malipopay(
        'k',
        environment: MalipopayEnvironment.uat,
        retries: 0,
        httpClient: spy.responding(
          (_, __) => _json({'message': 'Upstream down', 'code': 885}, 500),
        ),
      );

      await expectLater(
        client.payments.list(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Upstream down')
              .having((e) => e.code, 'code', 885),
        ),
      );
    });

    test('malformed JSON is an API error, not a connection error', () async {
      // The connection was fine. Reporting this as a connection failure sends
      // the caller into retry logic that cannot help.
      final spy = _Spy();
      final client = Malipopay(
        'k',
        environment: MalipopayEnvironment.uat,
        httpClient: spy.responding(
          (_, __) => http.Response('<html>502 Bad Gateway</html>', 200),
        ),
      );

      await expectLater(
        client.payments.list(),
        throwsA(isA<ApiException>()),
      );
    });

    test('429 surfaces the retry-after header', () async {
      final spy = _Spy();
      final client = Malipopay(
        'k',
        environment: MalipopayEnvironment.uat,
        retries: 0,
        httpClient: MockClient(
          (r) async => http.Response(
            jsonEncode({'message': 'slow down'}),
            429,
            headers: {'content-type': 'application/json', 'retry-after': '60'},
          ),
        ),
      );

      await expectLater(
        client.payments.list(),
        throwsA(
          isA<RateLimitException>()
              .having((e) => e.retryAfter, 'retryAfter', 60),
        ),
      );
      expect(spy.requests, isEmpty);
    });
  });

  group('environments', () {
    test('each environment carries its own gateway host', () {
      expect(MalipopayEnvironment.production.baseUrl,
          'https://core-prod.malipopay.co.tz');
      expect(
          MalipopayEnvironment.uat.baseUrl, 'https://core-uat.malipopay.co.tz');
      expect(MalipopayEnvironment.staging.baseUrl,
          'https://core-staging.malipopay.co.tz');
    });

    test('a request targets the selected environment', () async {
      final spy = _Spy();
      final client = Malipopay(
        'k',
        environment: MalipopayEnvironment.staging,
        httpClient:
            spy.responding((_, __) => _json({'data': <String, dynamic>{}})),
      );

      await client.payments.list();

      expect(spy.last.url.host, 'core-staging.malipopay.co.tz');
      expect(spy.last.url.path, '/api/v1/payment');
    });
  });
}
