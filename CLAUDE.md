# malipopay-flutter: Claude Context

**Flutter/Dart SDK.** Package `malipopay` on pub.dev (pubspec.yaml).

## Rules (inherited, do not restate here)

The parent `Malipopay/CLAUDE.md` auto-loads for this repo (parent-directory traversal) and carries everything that used to live in this file: the Malipopay naming convention (never "MaliPoPay"), per-language naming examples, SDK architecture (resource-oriented clients, `apiToken` header, error hierarchy), package registries, git flow, and company details.

- Base URLs: production `https://core-prod.malipopay.co.tz`, UAT `https://core-uat.malipopay.co.tz`
- API spec source of truth: `malipopay-openapi/openapi.yaml`; check it before adding or changing an endpoint binding
- Cross-SDK behaviour tests live in `malipopay-sdk-tests/scenarios/`; run the relevant scenario before declaring an SDK change done
