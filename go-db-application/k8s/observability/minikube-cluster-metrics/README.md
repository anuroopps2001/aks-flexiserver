# Kubernetes Cluster Metrics with Prometheus

This document explains **how Kubernetes cluster-level metrics work**, **how we installed and configured kube-state-metrics**, **what changes were required in Prometheus**, and **how to view these metrics locally using port-forwarding**.

This is written from a **hands-on, real-debugging perspective**, not as a theory-only guide.

---

## 1. What Are Kubernetes Cluster Metrics?

Kubernetes cluster metrics answer questions like:

* How many nodes are in the cluster?
* How many pods are running?
* Which pods are Pending / Failed?
* How many replicas does a Deployment want vs have?

These metrics **do NOT come from your application**.
They come from Kubernetes system components.

---

## 2. Metric Sources in Kubernetes

| Metric Type           | Source             | Example Metrics                     |
| --------------------- | ------------------ | ----------------------------------- |
| Cluster state         | kube-state-metrics | `kube_pod_info`, `kube_node_info`   |
| Pod / container usage | kubelet (cAdvisor) | `container_cpu_usage_seconds_total` |
| Node health           | node-exporter      | `node_cpu_seconds_total`            |

In this document we focus on **kube-state-metrics**, because it is the foundation for cluster observability.

---

## 3. What Is kube-state-metrics?

`kube-state-metrics` is a Kubernetes component that:

* Watches the Kubernetes API
* Converts Kubernetes objects into Prometheus metrics
* Exposes them on `/metrics`

Important:

> kube-state-metrics **does not measure usage** (CPU/memory).
> It reports **desired and actual state** of the cluster.

---

## 4. Installing kube-state-metrics (Offline / Restricted Network Friendly)

In our environment, `raw.githubusercontent.com` URLs were blocked.
So we used **Git + Kustomize**, which always works.

### Step 1: Clone the repository

```bash
git clone https://github.com/kubernetes/kube-state-metrics.git
cd kube-state-metrics
```

---

### Step 2: Apply the standard Kustomize manifests

```bash
kubectl apply -k examples/standard/
```

This installs:

* ServiceAccount
* ClusterRole / ClusterRoleBinding
* Deployment
* Service

---

### Step 3: Verify installation

```bash
kubectl get pods -n kube-system | grep kube-state-metrics
kubectl get svc -n kube-system | grep kube-state-metrics
```

Expected state:

```
kube-state-metrics-xxxx   1/1   Running
```

---

## 5. How kube-state-metrics Exposes Metrics

kube-state-metrics exposes metrics via a **Service** with multiple ports.

Example Service ports:

```yaml
ports:
- name: http-metrics
  port: 8080
  targetPort: http-metrics
- name: telemetry
  port: 8081
  targetPort: telemetry
```

Important distinction:

* **Service name** identifies *which workload*
* **Port name** identifies *which endpoint*

---

## 6. Prometheus Configuration Changes

Prometheus does **not automatically know** about kube-state-metrics.
We must explicitly scrape it.

### Scrape Strategy Used

We used **Endpoints Service Discovery** because it is:

* Deterministic
* Stable
* Used internally by Prometheus Operator / OpenShift

---

### Final Prometheus Scrape Job (Working)

```yaml
- job_name: "kube-state-metrics"
  kubernetes_sd_configs:
    - role: endpoints
  relabel_configs:
    # Keep only kube-state-metrics Service
    - source_labels: [__meta_kubernetes_service_name]
      action: keep
      regex: kube-state-metrics

    # Keep only the metrics port
    - source_labels: [__meta_kubernetes_endpoint_port_name]
      action: keep
      regex: http-metrics
```

After applying the ConfigMap, Prometheus was restarted:

```bash
kubectl rollout restart deployment prometheus -n monitoring
```

---

## 7. Verifying Scraping in Prometheus

### Prometheus UI

Navigate to:

```
Status → Targets
```

Expected:

```
kube-state-metrics   UP
```

---

## 8. Viewing Cluster Metrics Locally (Port-Forward)

Just like the Go application exposed `/metrics`, kube-state-metrics also exposes `/metrics`.

### Step 1: Find the pod

```bash
kubectl get pods -n kube-system | grep kube-state-metrics
```

---

### Step 2: Port-forward the metrics port

```bash
kubectl port-forward -n kube-system pod/<kube-state-metrics-pod-name> 8080:8080
```

---

### Step 3: View metrics locally

```bash
curl http://localhost:8080/metrics
```

You will see raw metrics like:

```text
kube_node_info{node="minikube"} 1
kube_pod_info{namespace="default",pod="go-db-app-..."} 1
kube_pod_status_phase{phase="Running"} 1
```

This confirms:

* kube-state-metrics is working
* Prometheus is scraping real data

---

## 9. Sample PromQL Queries (Cluster Metrics)

### Number of nodes

```promql
count(kube_node_info)
```

### Total pods

```promql
count(kube_pod_info)
```

### Running pods

```promql
count(kube_pod_status_phase{phase="Running"})
```

### Pods per namespace

```promql
count by (namespace) (kube_pod_info)
```

### Deployment replicas desired vs available

```promql
kube_deployment_spec_replicas
kube_deployment_status_replicas_available
```

---

## 10. Key Lessons Learned

1. Prometheus does **not generate metrics** — it only scrapes them
2. kube-state-metrics exposes **cluster state**, not usage
3. Endpoints Service Discovery is the most reliable
4. Service name and port name are different concepts
5. Port-forwarding is the fastest way to debug metric sources

---

## 11. Mental Model to Remember

```
Kubernetes API
   ↓
kube-state-metrics
   ↓
/metrics endpoint
   ↓
Prometheus
   ↓
PromQL / Grafana
```

---

## 12. Final Takeaway

> If Prometheus shows a metric, there is always a pod somewhere exposing it.

Understanding **where metrics originate** makes Prometheus predictable instead of painful.

---

**End of document**
