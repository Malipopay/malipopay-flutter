import 'package:http/http.dart' as http;

import 'auth.dart';
import 'http_client.dart';
import 'resources/account.dart';
import 'resources/customers.dart';
import 'resources/invoices.dart';
import 'resources/payments.dart';
import 'resources/products.dart';
import 'resources/references.dart';
import 'resources/sms.dart';
import 'resources/transactions.dart';
import 'webhooks.dart';

/// Malipopay environment.
enum MalipopayEnvironment {
  /// Production environment (real money).
  production('https://core-prod.malipopay.co.tz'),

  /// UAT environment. Tracks the `develop` branch of each service.
  uat('https://core-uat.malipopay.co.tz'),

  /// Staging environment. Tracks the `staging` branch.
  staging('https://core-staging.malipopay.co.tz');

  const MalipopayEnvironment(this.baseUrl);

  /// The base URL for this environment.
  final String baseUrl;
}

/// The main Malipopay SDK client.
///
/// Example:
/// ```dart
/// final client = Malipopay('your-api-key');
///
/// final payment = await client.payments.collect({
///   'description': 'Order #1234',
///   'amount': 10000,
///   'phoneNumber': '255712345678',
/// });
/// ```
class Malipopay {
  /// Creates a client authenticated with a project API token.
  ///
  /// [apiKey] is required. Get yours at https://app.malipopay.co.tz.
  ///
  /// This is the server-side persona. **Do not use it in a mobile or web app**:
  /// an API token is a project-wide secret, extractable from any shipped
  /// binary, and it is not scoped to a user. Use [Malipopay.session] there.
  Malipopay(
    String apiKey, {
    MalipopayEnvironment environment = MalipopayEnvironment.production,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 30),
    int retries = 2,
    String? webhookSecret,
    http.Client? httpClient,
  }) {
    if (apiKey.isEmpty) {
      throw ArgumentError(
          'Malipopay API key is required. Get yours at https://app.malipopay.co.tz');
    }
    _init(
      auth: ApiTokenAuth(apiKey),
      baseUrl: baseUrl ?? environment.baseUrl,
      timeout: timeout,
      retries: retries,
      webhookSecret: webhookSecret,
      httpClient: httpClient,
    );
  }

  /// Creates a client authenticated as a signed-in user acting on a project.
  ///
  /// This is the dashboard and mobile persona: `Authorization: Bearer <jwt>`
  /// plus a `project` header. Both are read through callbacks on every
  /// request, so refreshing a token or switching business needs no new client.
  ///
  /// ```dart
  /// final client = Malipopay.session(
  ///   SessionAuth(
  ///     token: () => secureStorage.read(key: 'access_token'),
  ///     projectId: () => scope.current?.id,
  ///     projectSlug: () => scope.current?.slug,
  ///   ),
  ///   environment: MalipopayEnvironment.uat,
  ///   onUnauthorized: authCubit.checkAuthStatus,
  /// );
  /// ```
  ///
  /// [onUnauthorized] fires on any 401 before the exception is thrown, which
  /// is where an app refreshes the session or signs the user out.
  Malipopay.session(
    SessionAuth auth, {
    MalipopayEnvironment environment = MalipopayEnvironment.production,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 30),
    int retries = 2,
    String? webhookSecret,
    Future<void> Function()? onUnauthorized,
    http.Client? httpClient,
  }) {
    _init(
      auth: auth,
      baseUrl: baseUrl ?? environment.baseUrl,
      timeout: timeout,
      retries: retries,
      webhookSecret: webhookSecret,
      onUnauthorized: onUnauthorized,
      httpClient: httpClient,
    );
  }

  void _init({
    required MalipopayAuth auth,
    required String baseUrl,
    required Duration timeout,
    required int retries,
    String? webhookSecret,
    Future<void> Function()? onUnauthorized,
    http.Client? httpClient,
  }) {
    _http = MalipopayHttpClient(
      baseUrl: baseUrl,
      auth: auth,
      timeout: timeout,
      retries: retries,
      onUnauthorized: onUnauthorized,
      httpClient: httpClient,
    );

    payments = Payments(_http);
    customers = Customers(_http);
    invoices = Invoices(_http);
    products = Products(_http);
    transactions = Transactions(_http);
    account = Account(_http);
    sms = Sms(_http);
    references = References(_http);
    webhooks = Webhooks(secret: webhookSecret);
  }

  late final MalipopayHttpClient _http;

  /// Payments resource (collect, disburse, verify, etc.)
  late final Payments payments;

  /// Customers resource (create, list, search, verify).
  late final Customers customers;

  /// Invoices resource (create, list, record payments).
  late final Invoices invoices;

  /// Products resource (create, list, update).
  late final Products products;

  /// Transactions resource (list, get, search).
  late final Transactions transactions;

  /// Account resource (account transactions, reconciliation, reports).
  late final Account account;

  /// SMS resource (send single, bulk, scheduled).
  late final Sms sms;

  /// Reference data resource (banks, currencies, countries).
  late final References references;

  /// Webhook signature verification and event parsing.
  late final Webhooks webhooks;

  /// Closes the underlying HTTP client.
  ///
  /// Call this when the client is no longer needed, typically on app shutdown.
  void close() => _http.close();
}
