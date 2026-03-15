# Prometheus + Kubernetes Debugging Journey (End‑to‑End)

This document captures **what we faced**, **why it happened**, and **how we finally fixed it** while integrating a Go application with Prometheus on Kubernetes (Minikube).

It is written as a **real-world troubleshooting guide**, not a happy-path tutorial.

---

## 1. Architecture Overview

### Components

* **Go Application**

  * Exposes HTTP APIs on port `8080`
  * Exposes Prometheus metrics on `/metrics`
* **PostgreSQL** (backend DB)
* **Kubernetes (Minikube)**
* **Prometheus** (self-managed, NOT Operator)

### Network Flow

```
Client → Service → Pod (Go App)
                   └── /metrics
Prometheus → Service → Endpoints → PodIP:8080/metrics
```

---

## 2. Where the Go Application Exposes Metrics

### Metrics Library Used

```go
import "github.com/prometheus/client_golang/prometheus"
import "github.com/prometheus/client_golang/prometheus/promhttp"
```

### Metrics Defined (`metrics.go`)

```go
var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_request_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "path", "status"},
    )

    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request latency",
        },
        []string{"path"},
    )
)

func init() {
    prometheus.MustRegister(httpRequestsTotal)
    prometheus.MustRegister(httpRequestDuration)
}
```

### Metrics Endpoint (`routes.go`)

```go
s.gorilla.Handle("/metrics", promhttp.Handler())
```

### Verification

```bash
curl http://<pod-ip>:8080/metrics
```

Metrics **were visible**, proving the application side was correct.

---

## 3. Prometheus Service Discovery Types (Important)

### 3.1 Pod Discovery (`role: pod`)

* Discovers Pods directly
* Prometheus must infer:

  * Pod IP
  * Container port
* **Fragile** and easy to break
* Relies heavily on relabeling

Used metadata:

```
__meta_kubernetes_pod_*
```

### 3.2 Service Discovery (`role: service`)

* Discovers Services
* Stable DNS
* Does NOT give Pod IPs directly
* Usually combined with Endpoints

### 3.3 Endpoints Discovery (`role: endpoints`) ✅ (Final Solution)

* Discovers **actual Pod IP + Port**
* Uses Kubernetes Endpoints object
* Most deterministic
* How Prometheus Operator / OpenShift works internally

Used metadata:

```
__meta_kubernetes_service_name
__meta_kubernetes_endpoint_port_name
__address__
```

---

## 4. The Problems We Faced (Chronological)

### Problem 1: Pod SD showed NO targets

**Symptoms**:

* `/metrics` works manually
* Prometheus shows zero targets
* No errors

**Root Cause**:

* Prometheus could not reliably construct `PodIP:Port`
* `localhost:8080` was mistakenly used (invalid in Kubernetes)

> `localhost` inside Prometheus means Prometheus itself, NOT the app pod

---

### Problem 2: Switched to Endpoints SD — still no targets

**Symptoms**:

* Service exists
* Endpoints exist
* Pod labels match Service selector
* Still zero targets

---

### Problem 3: Relabeling silently dropped everything

**Critical Discovery**:
Endpoints object:

```yaml
ports:
- name: go-db-service
  port: 8080
```

But Prometheus relabel rule expected:

```yaml
regex: http
```

❌ Mismatch caused **ALL endpoints to be dropped**

Prometheus **does not log this**.

---

### Problem 4: Mixing Pod Annotations with Endpoints SD

❌ Wrong (what we had):

```yaml
role: endpoints
source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
```

These labels **do not exist** for Endpoints.

---

## 5. Final Working Prometheus Configuration ✅

### Service (go app)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: go-db-service
  namespace: default
spec:
  selector:
    app: go-db
  ports:
    - name: http
      port: 8080
      targetPort: 8080
```

### Prometheus Scrape Job

```yaml
- job_name: "go-db-app"
  kubernetes_sd_configs:
    - role: endpoints
  relabel_configs:
    - source_labels: [__meta_kubernetes_service_name]
      action: keep
      regex: go-db-service

    - source_labels: [__meta_kubernetes_endpoint_port_name]
      action: keep
      regex: http
```

### Result

* Prometheus discovers endpoints
* `/metrics` scraped successfully
* Targets show **UP**
* Queries work:

```promql
http_request_total
http_request_duration_seconds_bucket
```

---

## 6. How Prometheus Is Scraping (Final Flow)

```
Prometheus
   ↓
Kubernetes API
   ↓
Endpoints object
   ↓
PodIP:8080
   ↓
GET /metrics
```

No guessing. No inference. No magic.

---

## 7. Key Lessons (Very Important)

1. **Annotations do NOT create targets** — they only filter existing ones
2. **Relabeling can drop everything silently**
3. **`localhost` is always wrong for inter-pod scraping**
4. **Endpoints are the ground truth**
5. **Port names matter**
6. Prometheus Operator exists for a reason 😄

---

**End of document**
