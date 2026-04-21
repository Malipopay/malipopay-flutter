import 'package:malipopay/malipopay.dart';
import 'package:test/test.dart';

void main() {
  group('Malipopay Client', () {
    test('throws if API key is empty', () {
      expect(() => Malipopay(''), throwsA(isA<ArgumentError>()));
    });

    test('creates a client with default production environment', () {
      final client = Malipopay('test-key');
      expect(client, isNotNull);
      expect(client.payments, isA<Payments>());
      expect(client.customers, isA<Customers>());
      expect(client.invoices, isA<Invoices>());
      expect(client.products, isA<Products>());
      expect(client.transactions, isA<Transactions>());
      expect(client.account, isA<Account>());
      expect(client.sms, isA<Sms>());
      expect(client.references, isA<References>());
      expect(client.webhooks, isA<Webhooks>());
      client.close();
    });

    test('accepts UAT environment', () {
      final client =
          Malipopay('test-key', environment: MalipopayEnvironment.uat);
      expect(client, isNotNull);
      client.close();
    });

    test('accepts custom base URL', () {
      final client = Malipopay('test-key', baseUrl: 'http://localhost:3000');
      expect(client, isNotNull);
      client.close();
    });

    test('accepts timeout and retries options', () {
      final client = Malipopay(
        'test-key',
        timeout: const Duration(seconds: 5),
        retries: 0,
      );
      expect(client, isNotNull);
      client.close();
    });
  });
}
