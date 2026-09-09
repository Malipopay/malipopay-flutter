/// Official Dart/Flutter SDK for the Malipopay payment platform.
///
/// Accept payments via Mobile Money (M-Pesa, Airtel Money, Mixx/YAS, Halopesa,
/// T-Pesa), Bank Transfer (CRDB, NMB), USSD (*146*08#), and Card (Visa,
/// Mastercard) in Tanzania.
///
/// Example:
/// ```dart
/// import 'package:malipopay/malipopay.dart';
///
/// void main() async {
///   final client = Malipopay('your-api-key');
///
///   final payment = await client.payments.collect({
///     'description': 'Order #1234',
///     'amount': 10000,
///     'phoneNumber': '255712345678',
///   });
///
///   print('Payment reference: ${payment['reference']}');
/// }
/// ```
library malipopay;

export 'src/auth.dart';
export 'src/client.dart';
export 'src/exceptions.dart';
// Exported so the resource classes, which are public and take one, can
// actually be constructed outside this package.
export 'src/http_client.dart' show MalipopayHttpClient;
export 'src/webhooks.dart' show Webhooks, WebhookEvent, WebhookEventType;
export 'src/resources/account.dart';
export 'src/resources/customers.dart';
export 'src/resources/invoices.dart';
export 'src/resources/payments.dart';
export 'src/resources/products.dart';
export 'src/resources/references.dart';
export 'src/resources/sms.dart';
export 'src/resources/transactions.dart';
