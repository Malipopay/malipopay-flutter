import 'package:malipopay/malipopay.dart';

Future<void> main() async {
  final client = Malipopay('your-api-key');

  try {
    // Create a customer
    final customer = await client.customers.create({
      'phoneNumber': '255712345678',
      'firstname': 'John',
      'lastname': 'Doe',
      'email': 'john@example.com',
    });

    // Create an invoice
    final invoice = await client.invoices.create({
      'customer': customer['_id'],
      'items': [
        {'description': 'Web Development', 'quantity': 1, 'unitPrice': 500000},
        {'description': 'Hosting (1 year)', 'quantity': 1, 'unitPrice': 120000},
      ],
      'dueDate': '2026-05-01',
      'currency': 'TZS',
      'taxRate': 18,
    });

    print('Invoice created: ${invoice['reference']}');
    print('Total: ${invoice['total']} ${invoice['currency']}');
  } finally {
    client.close();
  }
}
