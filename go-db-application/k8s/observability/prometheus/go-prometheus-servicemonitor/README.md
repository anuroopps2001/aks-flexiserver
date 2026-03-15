# ServiceMonitor with Prometheus Operator (Helm-based Setup)

This document explains **how to install Prometheus using Helm**, **why Prometheus Operator is required for ServiceMonitor**, and **how we exposed a Go application using ServiceMonitor**.

This README is based on a **real troubleshooting journey**, including common failure modes like `0/0 targets` and how we fixed them.

---

## 1. Why Prometheus Operator?

Raw Prometheus requires manual:

* scrape configs
* relabeling
* config reloads

Prometheus Operator introduces CRDs:

* `ServiceMonitor`
* `PodMonitor`
* `PrometheusRule`

These **generate Prometheus scrape config automatically**.

> OpenShift internally uses the Prometheus Operator.

---

## 2. Install Prometheus Operator using Helm

### Add Helm repo

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

---

### Install kube-prometheus-stack

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace
```

This installs:

* Prometheus
* Prometheus Operator
* Grafana
* Alertmanager
* kube-state-metrics

---

### Verify installation

```bash
kubectl get pods -n monitoring
```

Expected components:

* `monitoring-kube-prometheus-operator`
* `prometheus-monitoring-kube-prometheus-prometheus-0`
* `monitoring-kube-state-metrics`
* `monitoring-grafana`

---

## 3. Understanding ServiceMonitor Selection

Prometheus Operator **does not scrape every ServiceMonitor**.

It only selects ServiceMonitors with matching labels.

Check Prometheus selector:

```bash
kubectl get prometheus -n monitoring -o yaml | grep -A5 serviceMonitorSelector
```

Typical output:

```yaml
serviceMonitorSelector:
  matchLabels:
    release: monitoring
```

This means:

> Only ServiceMonitors with `release=monitoring` will be picked up.

---

## 4. Go Application Service Requirements

Your Kubernetes Service **must** have:

1. Correct labels
2. Named port

### Example Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: go-db-service
  labels:
    app: go-db
spec:
  selector:
    app: go-db
  ports:
    - name: http
      port: 8080
      targetPort: 8080
```

> The **port name** is mandatory for ServiceMonitor matching.

---

## 5. ServiceMonitor for Go Application

### ServiceMonitor manifest

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: go-db-app
  namespace: monitoring
  labels:
    release: monitoring
spec:
  selector:
    matchLabels:
      app: go-db
  namespaceSelector:
    matchNames:
      - default
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
```

Apply it:

```bash
kubectl apply -f go-db-servicemonitor.yaml
```

---

## 6. Debugging "0/0" Targets (Key Learning)

If Prometheus shows:

```
serviceMonitor/monitoring/go-db-app/0   0/0
```

It means:

> Prometheus found the ServiceMonitor but matched **no Service endpoints**.

### Common causes

| Cause                   | Result          |
| ----------------------- | --------------- |
| Missing `release` label | Job not created |
| Service label mismatch  | 0/0 targets     |
| Port name mismatch      | 0/0 targets     |
| No endpoints            | 0/0 targets     |

### Troubleshooting to confirm prometheus picked up correct ServiceMonitor
```bash
kubectl get pods -n monitoring | grep prometheus
alertmanager-monitoring-kube-prometheus-alertmanager-0   2/2     Running   0          31m
monitoring-kube-prometheus-operator-7fb4d484b9-cfgfv     1/1     Running   0          32m
monitoring-prometheus-node-exporter-h7gxh                1/1     Running   0          32m
prometheus-monitoring-kube-prometheus-prometheus-0       2/2     Running   0          31m
ubuntu@ip-10-0-1-89:~$

ubuntu@ip-10-0-1-89:~$ kubectl exec -n monitoring -it prometheus-monitoring-kube-prometheus-prometheus-0 -- sh

/prometheus $ ls /etc/prometheus/
certs           config_out      prometheus.yml  rules           web_config

/prometheus $ grep go-db /etc/prometheus/config_out/prometheus.env.yaml
- job_name: serviceMonitor/monitoring/go-db-app/0
    regex: (go-db);true
/prometheus
```
#### Prometheus Operator constructs job names using this pattern:
```bash
serviceMonitor/<namespace>/<servicemonitor-name>/<endpoint-index>
```

So in my case:
```bash
serviceMonitor / monitoring / go-db-app / 0
```

### Fix checklist

```bash
kubectl get svc go-db-service -o yaml
kubectl get endpoints go-db-service
kubectl get servicemonitor -n monitoring go-db-app -o yaml
```

---

## 7. Verifying Prometheus Configuration Internals

Check if Operator generated the scrape job:

```bash
kubectl exec -n monitoring -it prometheus-monitoring-kube-prometheus-prometheus-0 -- \
  grep go-db /etc/prometheus/config_out/prometheus.env.yaml
```

Expected:

```
job_name: serviceMonitor/monitoring/go-db-app/0
```

---

## 8. Verifying Targets in Prometheus UI

Port-forward Prometheus:

```bash
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Open:

```
http://localhost:9090
```

Navigate to:

```
Status → Targets
```

Expected:

```
serviceMonitor/monitoring/go-db-app/0   UP
```

---

## 9. Verifying Metrics

Example PromQL queries:

```promql
http_request_total
count(kube_node_info)
count(kube_pod_info)
```

---

## 10. Viewing Metrics at Source (Port-Forward)

Just like the application, metrics can be viewed directly.

```bash
kubectl port-forward svc/go-db-service 8080:8080
curl http://localhost:8080/metrics
```

This confirms:

* application is exporting metrics
* Prometheus is scraping correctly

---

## 11. Key Takeaways

* ServiceMonitor replaces manual Prometheus scrape configs
* Port names matter
* Labels matter
* `0/0` targets always mean Service/endpoint mismatch
* Operator abstracts complexity, not logic

---

## 12. Mental Model

```
Application → Service → Endpoints → ServiceMonitor → Prometheus Operator → Prometheus
```

---

**End of document**
