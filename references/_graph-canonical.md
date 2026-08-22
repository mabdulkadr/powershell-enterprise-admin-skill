# Canonical Graph API — Single Source of Truth

> **DO NOT DUPLICATE.** All Graph pagination/auth/retry/batch logic lives in `scripts/` — reference only.

## Scripts (copy verbatim, never retype)

| Script | Purpose |
|--------|---------|
| `scripts/Get-MgGraphAllPages.ps1` | Pagination via `@odata.nextLink`, `List[PSCustomObject]` append, Retry-After aware 429 handling |
| `scripts/Invoke-GraphRequestWithRetry.ps1` | Retry wrapper: 429 (Retry-After header or exponential backoff capped 60s) + 5xx exponential backoff, 3 retries default |
| `scripts/Invoke-GraphBatchRequest.ps1` | `$batch` engine (20 ops/batch), calls `Invoke-GraphRequestWithRetry` per chunk |
| `scripts/Connect-GraphAuth.ps1` | Auth matrix: Managed Identity (Azure Automation), Interactive/DeviceCode, Client Credentials |
| `scripts/Get-Graph403Message.ps1` | `403 →` actionable role mapping (7 services) |

## ValidateSet (unified — 7 values in BOTH files)

```
EntraID, Intune, Autopilot, Exchange, Defender, Teams, SharePoint
```

Must be identical in `Invoke-GraphRequestWithRetry.ps1` and `Get-Graph403Message.ps1`.

## Retry Policy

- **429:** honor `Retry-After` header if present, else exponential backoff `pow(2, attempt) * BaseDelaySeconds` capped at 60s
- **5xx:** exponential backoff
- `MaxRetries = 3` default, configurable via `-MaxRetries` / `-Max429Retries`

## Usage

```powershell
# Pagination
$devices = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/v1.0/devices"

# Retry
Invoke-GraphRequestWithRetry -Uri "https://graph.microsoft.com/v1.0/users" -Service "EntraID"

# Batch
Invoke-GraphBatchRequest -Requests $requests -Service "Intune"
```

## Auth Context Detection

- Azure Automation: `$PSPrivateMetadata.JobId.Guid` or `$env:AUTOMATION_ASSET_ACCOUNTID` → `Connect-MgGraph -Identity`
- Local: `Connect-MgGraph -Scopes` or `Connect-MgGraphCommunity`

## Government Clouds (GCC / GCC High / DoD / China)

Scripts must not hard-code the global endpoint. Tenants on sovereign clouds fail with confusing auth errors against `graph.microsoft.com`. Detect or parameterize the environment:

| Cloud | Graph endpoint | Auth authority | MgGraph `-Environment` |
|-------|----------------|----------------|------------------------|
| Global (commercial) | `https://graph.microsoft.com` | `login.microsoftonline.com` | `Global` |
| GCC High | `https://graph.microsoft.us` | `login.microsoftonline.us` | `USGov` |
| DoD | `https://dod-graph.microsoft.us` | `login.microsoftonline.us` | `USGovDoD` |
| China (21Vianet) | `https://microsoftgraph.chinacloudapi.cn` | `login.chinacloudapi.cn` | `China` |

```powershell
# Module-based: switch environment BEFORE Connect-MgGraph
Connect-MgGraph -Environment USGov -Scopes $scopes -NoWelcome

# Raw Invoke-RestMethod: derive base URI + token authority from one config variable
$GraphBase = 'https://graph.microsoft.us'   # single source in CONFIGURATION block
$TokenUri  = "https://login.microsoftonline.us/$TenantId/oauth2/v2.0/token"
```

Rules:
- One `$GraphBase` variable in the CONFIGURATION region — every URI concatenates from it; never scatter literal endpoints through the script.
- Batch and pagination helpers (`Invoke-GraphBatchRequest`, `Get-MgGraphAllPages`) inherit the base from their `-Uri` argument, so sovereign clouds need no helper changes.
- Beta surface availability differs per cloud — verify the endpoint exists before assuming parity with Global.

See `intune-patterns.md` and `notification-patterns.md` for full deployment patterns.
