# plans

Pending work and debt for `malipopay-flutter`. Pruned as it ships.

## Next: 1.2.0, typed models and the missing resources

Every method still returns `Future<dynamic>`, so every caller indexes untyped
maps and `strict-casts` forces an `as` on each read. Planned: hand-written
models (no codegen, matching the house convention) for Payment, Customer,
Invoice, Product, Receipt, PaymentLink, PayMePage, SmsMessage and Institution,
plus a `MalipopayResponse<T>` that keeps the envelope's `success`, `code` and
`message` instead of discarding them.

New resources the merchant app needs and neither this SDK nor the Node SDK has:

- `paymentsV2`: `/api/v2/payment/{collection,disbursement,disbursement/batch,channels,pay}`
- `links`: `PUT /payment` link intents, `GET /payment/link/{code}`, `/payment/qr`, `/payment/share-link/{reference}`
- `payMe`: page CRUD, active toggle, slug check, transactions
- `receipts`: list, search, get, public link
- `settlements`: wallet balance including the reserve, accounts CRUD and verify, create, list, cancel
- `payments.breakdown`, `payments.limits`, `payments.report`
- `invoices.shareLink`, `invoices.systemReceipt`
- `products.update(id, ...)`: the current `update` takes no id, so the id has to be smuggled in the body

## 1.3.0, POS and messaging extras

`pos.charge(cart, method)` composing a v2 collection push, bounded verify
polling and a receipt. Cash tender has no backend endpoint, so it returns an
explicit unsupported result rather than pretending. Plus `sms.credits`,
`sms.prices`, `sms.buyCredits` and `sms.senderIds` (through `/company/sender-ids`,
because `sender-ids` is not on the gateway allowlist).

## Repo debt

- **No `develop` or `staging` branch.** The org runs `feature/* -> develop ->
  staging -> main` and this repo has only `main`. CI also only triggers on
  `main`, so feature branches get no checks.
- `pubspec.lock` is committed and also listed in `.gitignore`.
- `meta` is a declared dependency and is imported nowhere.
- The webhook signature header name (`X-Malipopay-Signature`) exists only in an
  example file, not in the library or its docs.
- `malipopay-sdk-tests` has no Dart row in its README, no JWT scenarios, and no
  webhook scenario. Its own README spells the brand "MaliPoPay" throughout,
  which the house convention forbids.

## Backend asks raised by this work

- An idempotency-key header on collection and disbursement, so a retry is safe
  without relying on a caller-supplied reference.
- A POS cash-sale endpoint.
- A fee-quote endpoint. Bank of Tanzania guideline 16(4) requires the fee to be
  disclosed before the payer confirms, and today it has to be computed client
  side from the banded tariff.
- `bearerAuth` applied to the public OpenAPI paths, plus the `project` header
  parameter, now that the SDK speaks persona 1.
