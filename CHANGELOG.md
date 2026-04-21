## 1.0.0

- Initial release of the Malipopay Dart/Flutter SDK.
- Resource-oriented API: payments, customers, invoices, products, transactions, account, sms, references.
- Webhook signature verification (HMAC-SHA256).
- Error hierarchy: `MalipopayException`, `AuthenticationException`, `ValidationException`, `RateLimitException`, `ApiException`, `ConnectionException`.
- Automatic retries with exponential backoff on 429/5xx.
- Production and UAT environment support.
