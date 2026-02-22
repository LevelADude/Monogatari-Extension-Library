# CI Sample Summary

## Format definition
- Columns: `Extension | Status | Notes`
- Status values: `PASS`, `FAIL`, `SKIP`.
- `SKIP` entries include explicit reason (for example JS rendering, auth, or anti-bot barriers).

## Example
| Extension | Status | Notes |
|---|---|---|
| RoyalRoad | PASS | all checks passed |
| Webnovel | SKIP | Requires dynamic JS/auth and anti-bot protected endpoints |
| FanFiction.Net | FAIL | chapter http 403 |

## Run results
| Extension | Status | Notes |
|---|---|---|
| Not executed in local sandbox | SKIP | Network restrictions prevented downloading extension-tester and running live checks |
