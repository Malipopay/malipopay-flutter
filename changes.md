# changes

What shipped in `malipopay-flutter` and why. Newest first, one entry per merged PR.

## 2026-09-10 · #2 · Keep the internal working records out of the published archive

**Why.** `dart pub publish --dry-run` listed `CLAUDE.md`, `changes.md`,
`plans.md` and `docs/plans/2026-09-07-dual-auth.md` in the archive. Those are
internal Lockwood records, not documentation for the package's users, and a
pub.dev version cannot be unpublished, so the moment to catch it is before the
first publish that would carry them.

**What changed.** A `.pubignore` excluding those four, which also settles pub's
"rename docs/ to doc/" warning: the only thing under `docs/` is a planning
note, so it is excluded rather than renamed. The archive goes from 23 KB to
18 KB and the dry-run from one warning to zero.

**The trap this file is written around.** `.pubignore` REPLACES `.gitignore`
for publishing rather than adding to it, so anything `.gitignore` covered and
`.pubignore` does not would silently start being published. Every non-comment
line of `.gitignore` is therefore restated here, `.env` and `coverage/`
included, and there is a check for it: no `.gitignore` entry is missing from
`.pubignore`.

---

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

**Correction, 2026-09-07, before merge.** The first version of the retry fix
kept an exception: a POST carrying a caller-supplied `reference` was still
retried, on the belief that the backend treated that reference as an
idempotency key. **It does not.** Measured against UAT: two
`POST /api/v2/payment/collection` calls with the identical `reference` of
`MRCH629732` produced two separate payments, `MU00206` and `MU00207`, both for
1,000 TZS. The caller's value is stored as `customerReference`, a label, while
the payment's own reference is minted server-side, and
`GET /payment/verify/{reference}` does not resolve by the caller's one.

So no POST is retried at all. This is not a rare edge: the same call took **41
seconds** on its first attempt, longer than most default client timeouts, and
a timed-out attempt in that session (`MRCH709895`) DID create a payment,
`MU00205`, which the client never learned about. Restore the exception only
when the backend accepts a real idempotency key and answers a repeat with the
original payment.

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
