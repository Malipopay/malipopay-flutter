import 'package:malipopay/malipopay.dart';
import 'package:test/test.dart';

void main() {
  group('Exceptions', () {
    test('MalipopayException has correct properties', () {
      final e = MalipopayException('test',
          statusCode: 500, code: 1001, details: 'detail');
      expect(e.message, equals('test'));
      expect(e.statusCode, equals(500));
      expect(e.code, equals(1001));
      expect(e.details, equals('detail'));
      expect(e.toString(), contains('test'));
    });

    test('AuthenticationException defaults to 401', () {
      final e = AuthenticationException();
      expect(e.statusCode, equals(401));
      expect(e, isA<MalipopayException>());
    });

    test('PermissionException defaults to 403', () {
      expect(PermissionException().statusCode, equals(403));
    });

    test('NotFoundException defaults to 404', () {
      expect(NotFoundException().statusCode, equals(404));
    });

    test('ValidationException supports field errors', () {
      final e = ValidationException('Invalid', fields: {
        'phoneNumber': 'Required',
        'amount': 'Must be positive',
      });
      expect(e.statusCode, equals(422));
      expect(e.fields?['phoneNumber'], equals('Required'));
    });

    test('RateLimitException supports retryAfter', () {
      final e = RateLimitException('slow down', 60);
      expect(e.statusCode, equals(429));
      expect(e.retryAfter, equals(60));
    });

    test('ApiException carries status code', () {
      final e = ApiException('Server error', 502, code: 5002);
      expect(e.statusCode, equals(502));
      expect(e.code, equals(5002));
    });

    test('ConnectionException has no status code', () {
      final e = ConnectionException();
      expect(e.statusCode, isNull);
    });
  });
}
