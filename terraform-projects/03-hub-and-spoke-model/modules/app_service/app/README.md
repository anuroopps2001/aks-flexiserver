```bash
$ az webapp deploy \
  --resource-group rg-hub-networking \
  --name go-db-app-ui-prod \
  --slot staging \
  --src-path modules/app_service/frontend.zip \
  --type zip
```

### KQL queries based on the tables stored inside the Application Insights

Since we are using Application insights SDK in nodejs application for appservice, we see the below tables
Tables stored inside the Application Insights:
```bash
requests       → incoming HTTP calls
dependencies   → outgoing calls (API, DB, etc.)
traces         → logs (console, debug info)
exceptions     → errors
customEvents   → your manual events
```
requests       → incoming HTTP calls
dependencies   → outbound calls (AKS, DB)
traces         → logs
exceptions     → errors

👉 These come from:

**Application Insights SDK / auto-instrumentation**


Corresponding sample KQL queries:

CustomEvents:
```bash
customEvents
| order by timestamp desc
```

Traces:
```bash
traces
| order by timestamp desc
```

Requests:
```bash
requests
| order by timestamp desc
```

```bash
requests
| where toint(resultCode) >= 400
| summarize count() by name, resultCode
| order by count_ desc
```

Failure rate:
```bash
requests
| summarize 
    total = count(),
    failures = countif(toint(resultCode) >= 400)
| extend failureRate = failures * 100.0 / total
```

Slow + failing requests:
```bash
requests
| where toint(resultCode) >= 400
| where duration > 2s
| order by duration desc
```

Specific endpoint failures:
```bash
requests
| where name contains "upload"
| where toint(resultCode) >= 400
| order by timestamp desc
```
Summary based on StatusCodes:
```bash
requests
| summarize count() by resultCode
| order by count_ desc
```

### Alerting conditions

When FailureRate > 5%:
```bash
requests
| where name in ("POST /api/upload", "GET /api/users")
| summarize 
    total = count(),
    failures = countif(toint(resultCode) >= 400)
| extend failureRate = failures * 100.0 / total
```

Filter by success + real traffic:
```bash
requests
| where name !contains "health"
| where name startswith "POST /api"
| summarize 
    total = count(),
    failures = countif(success == false)
| extend failureRate = failures * 100.0 / total
```


Failures and FailureRates based on endpoints:
```bash
requests
| where name !contains "health"
| summarize 
    total = count(),
    failures = countif(success == false)
by name
| extend failureRate = failures * 100.0 / total
| order by failureRate desc
```

```bash
requests
| where name !contains "health"
| where name !contains "favicon"
| where name startswith "POST /api"
| summarize 
    total = count(),
    failures = countif(success == false)
| extend failureRate = failures * 100.0 / total
```
```bash
requests
| where toint(resultCode) >= 500
| summarize count() by name
| order by count_ desc
```

```bash
requests
| where name !contains "health"
| where name startswith "POST /api"
| summarize 
    total = count(),
    failures = countif(success == false),
    endpoints = make_set(name)
| where total > 10
| extend failureRate = failures * 100.0 / total
```

### Latency related queries
```bash
requests
| where name !contains "health"
| extend durationSec = duration / 1000
| extend durationMs = duration
| project name, durationMs, durationSec
| order by durationMs desc
```

```bash
requests
| where name !contains "health"
| where duration > 2000
| extend durationSec = duration / 1000.0
| project name, durationSec, resultCode
| order by durationSec desc
```