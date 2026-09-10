## 1.1.0

### Added

- **Dashboard and mobile authentication.** `Malipopay.session(SessionAuth(...))`
  authenticates as a signed-in user acting on a project, sending
  `Authorization: Bearer` plus a `project` header. The token and project are
  read through callbacks on every request, so refreshing a token or switching
  business needs no new client. `Malipopay(apiKey)` is unchanged.
- `onUnauthorized`, called on any 401 before the exception is thrown, for apps
  that need to refresh or sign the user out.
- `MalipopayEnvironment.staging`.
- `MalipopayHttpClient` is exported, so the public resource classes can
  actually be constructed outside the package.

### Fixed

- **POST is no longer retried blindly.** A `/payment/collection` or
  `/payment/disbursement` that timed out may already have moved money, and the
  response cannot say which side of the wire failed. POST is retried only when
  the caller supplied a `reference`, which is the backend's idempotency key.
  GET, PUT and DELETE are unchanged.
- HTTP 400 now raises `ValidationException` rather than a generic
  `ApiException`. Central-api returns 400 for most validation failures.
- `ValidationException.fields` is populated from the response, accepting both
  `{"field": "reason"}` and `{"field": ["reason"]}`.
- Error messages prefer the response's `details` over `message`. `message`
  carries a code label, which is why failures used to read as
  `controller:x:y->error`.
- The business `code` is attached on every error, not only the default branch.
- A malformed response body raises `ApiException` instead of
  `ConnectionException`. The connection was fine.

### Tests

First HTTP coverage in the package: auth header selection per persona and per
path, retry safety, error mapping, and a conformance runner that executes the
shared `malipopay-sdk-tests` scenarios against a mock transport.

## 1.0.0

- Initial release of the Malipopay Dart/Flutter SDK.
- Resource-oriented API: payments, customers, invoices, products, transactions, account, sms, references.
- Webhook signature verification (HMAC-SHA256).
- Error hierarchy: `MalipopayException`, `AuthenticationException`, `ValidationException`, `RateLimitException`, `ApiException`, `ConnectionException`.
- Automatic retries with exponential backoff on 429/5xx.
- Production and UAT environment support.
