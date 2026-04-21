import 'package:malipopay/malipopay.dart';

Future<void> main() async {
  final client = Malipopay(
    'your-api-key',
    environment: MalipopayEnvironment.uat,
  );

  try {
    // Collect TZS 10,000 via mobile money
    final payment = await client.payments.collect({
      'description': 'Order #1234',
      'amount': 10000,
      'phoneNumber': '255712345678',
    });

    print('Payment initiated: $payment');
    print('Reference: ${payment['reference']}');

    // Verify payment status
    final status = await client.payments.verify(payment['reference'] as String);
    print('Status: $status');
  } on AuthenticationException catch (e) {
    print('Invalid API key: ${e.message}');
  } on ValidationException catch (e) {
    print('Validation failed: ${e.message}');
    print('Fields: ${e.fields}');
  } on MalipopayException catch (e) {
    print('Malipopay error: ${e.message}');
  } finally {
    client.close();
  }
}
