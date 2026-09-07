# changes

What shipped in `malipopay-flutter` and why. Newest first, one entry per merged PR.

## 2026-09-07 · #1 · Dashboard/mobile auth, safe retries, and the first HTTP tests

**Why.** The Malipopay merchant mobile app needs this SDK for payments,
invoices, products, receipts, links and SMS, and it authenticates as persona 1
(a user's JWT plus a project header). The package only spoke persona 2, a
single `apiToken` header hardcoded in one place, and an API token cannot ship
in a mobile binary: it is extractable from any APK or IPA and is not scoped to
a user.

Auditing it for that also turned up a live correctness problem. Every POST was
retried on timeout and 5xx with no idempotency key, so a collection or
disbursement that timed out after reaching the backend was re-sent, and neither
the SDK nor the caller could tell whether money had already moved.

**What changed.** `Malipopay.session(SessionAuth(...))` alongside the existing
`Malipopay(apiKey)`, emitting exactly one credential set, never both, with the
`project` header carrying the slug on the messaging paths and the project id
everywhere else. POST retries only with a caller-supplied `reference`. Error
mapping now reads `details` before `message`, populates
`ValidationException.fields`, treats 400 as validation, and stops reporting a
malformed body as a connection failure. 60 tests where there were 21, including
the package's first HTTP coverage and a runner for the shared conformance
scenarios.

**Plan:** docs/plans/2026-09-07-dual-auth.md · **Related:** the merchant app
consumes this from M1.
