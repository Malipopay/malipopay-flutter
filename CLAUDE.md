# Malipopay SDK Development Rules

## Naming Convention — CRITICAL

The brand name is **Malipopay** (single capital M, all lowercase after). Never use "MaliPoPay" with capital P-o-P.

| Context | Correct | Wrong |
|---------|---------|-------|
| PascalCase class | `Malipopay` | `MaliPoPay` |
| Error class | `MalipopayError` | `MaliPoPayError` |
| Exception class | `MalipopayException` | `MaliPoPayException` |
| Config type | `MalipopayConfig` | `MaliPoPayConfig` |
| Options type | `MalipopayOptions` | `MaliPoPayOptions` |
| Client class | `MalipopayClient` | `MaliPoPayClient` |
| Module/package | `malipopay` | ✅ already correct |
| In docs/prose | "Malipopay" or "malipopay" | "MaliPoPay" |
| URLs/paths | `malipopay` | ✅ already correct |

### Per-Language Examples

```typescript
// Node.js / TypeScript
import { Malipopay, MalipopayError } from "malipopay";
const client = new Malipopay("api-key");
```

```python
# Python
from malipopay import Malipopay, AsyncMalipopay, MalipopayError
client = Malipopay("api-key")
```

```php
// PHP
use Malipopay\Malipopay;
use Malipopay\Exceptions\MalipopayException;
$client = new Malipopay("api-key");
```

```java
// Java
import tz.co.malipopay.Malipopay;
import tz.co.malipopay.MalipopayConfig;
Malipopay client = new Malipopay("api-key");
```

```csharp
// C# / .NET
using Malipopay;
var client = new MalipopayClient("api-key");
```

```ruby
# Ruby
require "malipopay"
client = Malipopay::Client.new(api_key: "api-key")
```

## SDK Architecture

- **Resource-oriented:** `client.payments.collect()`, `client.customers.create()`
- **Auth:** `apiToken` header (API key from dashboard)
- **Base URLs:**
  - Production: `https://core-prod.malipopay.co.tz`
  - UAT: `https://core-uat.malipopay.co.tz`
- **Error hierarchy:** `MalipopayError` → `AuthenticationError`, `ValidationError`, `NotFoundError`, `PermissionError`, `RateLimitError`, `ApiError`, `ConnectionError`

## GitHub Organization

https://github.com/Malipopay

## Package Registries

| Language | Package | Registry |
|----------|---------|----------|
| Node.js | `malipopay` | npm |
| Python | `malipopay` | PyPI |
| PHP | `malipopay/malipopay-php` | Packagist |
| Java | `tz.co.malipopay:malipopay-java` | Maven Central |
| .NET | `Malipopay` | NuGet |
| Ruby | `malipopay` | RubyGems |

## Company

- **Company:** Lockwood Technology Ltd
- **Product:** Malipopay
- **Website:** malipopay.co.tz
- **Developer Docs:** developers.malipopay.co.tz
- **Support:** support@malipopay.co.tz
