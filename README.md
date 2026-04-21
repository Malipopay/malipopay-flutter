# Malipopay Dart/Flutter SDK

Official Dart/Flutter SDK for the [Malipopay](https://malipopay.co.tz) payment platform. Accept payments via Mobile Money (M-Pesa, Airtel Money, Mixx/YAS, Halopesa, T-Pesa), Bank Transfer (CRDB, NMB), USSD, and Card (Visa, Mastercard) in Tanzania.

## Installation

```bash
flutter pub add malipopay
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  malipopay: ^1.0.0
```

## Quick Start

```dart
import 'package:malipopay/malipopay.dart';

Future<void> main() async {
  final client = Malipopay('your-api-key');

  final payment = await client.payments.collect({
    'description': 'Order #1234',
    'amount': 10000,
    'phoneNumber': '255712345678',
  });

  print('Reference: ${payment['reference']}');
}
```

## Configuration

```dart
final client = Malipopay(
  'your-api-key',
  environment: MalipopayEnvironment.uat,        // .production or .uat
  timeout: Duration(seconds: 30),                // default: 30s
  retries: 2,                                    // default: 2
  webhookSecret: 'whsec_...',                   // for webhook verification
);
```

## Usage

### Payments

```dart
// Collect via mobile money
final payment = await client.payments.collect({
  'description': 'Order #1234',
  'amount': 10000,
  'phoneNumber': '255712345678',
});

// Disburse funds
await client.payments.disburse({
  'description': 'Salary payment',
  'amount': 50000,
  'phoneNumber': '255712345678',
});

// Verify payment
final status = await client.payments.verify('PAY-abc123');

// Create payment link
final link = await client.payments.createLink({
  'amount': 25000,
  'phoneNumber': '255712345678',
});
```

### Customers

```dart
final customer = await client.customers.create({
  'phoneNumber': '255712345678',
  'firstname': 'John',
  'lastname': 'Doe',
  'email': 'john@example.com',
});

final results = await client.customers.search({'query': 'John'});
```

### Invoices

```dart
final invoice = await client.invoices.create({
  'customer': 'customer-id',
  'items': [
    {'description': 'Web Development', 'quantity': 1, 'unitPrice': 500000},
  ],
  'dueDate': '2026-05-01',
  'currency': 'TZS',
  'taxRate': 18,
});
```

### SMS

```dart
await client.sms.send({
  'sender': 'MALIPOPAY',
  'phoneNumber': '255712345678',
  'message': 'Your payment was received!',
});

await client.sms.sendBulk({
  'sender': 'MALIPOPAY',
  'phoneNumber': ['255712345678', '255713456789'],
  'message': 'Special offer!',
});
```

### Reference Data

```dart
final banks = await client.references.banks();
final currencies = await client.references.currencies();
final countries = await client.references.countries();
```

## Webhook Handling

```dart
final webhooks = Webhooks(secret: 'whsec_your_secret');

final event = webhooks.constructEvent(rawBody, signatureHeader);

switch (event.type) {
  case WebhookEventType.paymentCompleted:
    print('Payment completed: ${event.data['reference']}');
  case WebhookEventType.paymentFailed:
    print('Payment failed');
}
```

## Error Handling

```dart
try {
  await client.payments.collect({...});
} on AuthenticationException catch (e) {
  print('Invalid API key: ${e.message}');
} on ValidationException catch (e) {
  print('Validation failed: ${e.fields}');
} on RateLimitException catch (e) {
  print('Rate limited, retry after ${e.retryAfter}s');
} on MalipopayException catch (e) {
  print('Error: ${e.message}');
}
```

## Requirements

- Dart SDK ^3.0.0
- Flutter (if using in a Flutter app)
- Malipopay API key ([get one here](https://app.malipopay.co.tz))

## License

MIT

---

## See Also

| SDK | Install |
|-----|---------|
| [Node.js](https://github.com/Malipopay/malipopay-node) | `npm install malipopay` |
| [Python](https://github.com/Malipopay/malipopay-python) | `pip install malipopay` |
| [PHP](https://github.com/Malipopay/malipopay-php) | `composer require malipopay/malipopay-php` |
| [Java](https://github.com/Malipopay/malipopay-java) | Maven / Gradle |
| [.NET](https://github.com/Malipopay/malipopay-dotnet) | `dotnet add package Malipopay` |
| [Ruby](https://github.com/Malipopay/malipopay-ruby) | `gem install malipopay` |
| [Flutter/Dart](https://github.com/Malipopay/malipopay-flutter) | `flutter pub add malipopay` |

[API Reference](https://developers.malipopay.co.tz) | [OpenAPI Spec](https://github.com/Malipopay/malipopay-openapi)
