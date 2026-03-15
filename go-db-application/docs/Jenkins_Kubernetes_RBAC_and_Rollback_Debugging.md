
# Jenkins ↔ Kubernetes (Minikube) Integration — Full Debugging & RBAC Walkthrough

**Date:** 2026-01-06  
**Objective:**  
Enable Jenkins to deploy to a Kubernetes cluster (Minikube on EC2) **securely and reliably**, with:
- Proper kubeconfig handling
- RBAC (least privilege)
- Rollback on failure
- Understanding of real-world CI/CD behavior

This document is intentionally detailed and includes **every major error encountered**, **why it happened**, and **how it was fixed**.

---

## 1. Initial Goal

- Jenkins should deploy a Docker image to Kubernetes
- Jenkins must NOT run as cluster-admin
- Deployment should:
  - wait for rollout
  - rollback automatically on failure

---

## 2. First Problem: Jenkins could not access Kubernetes

### Error

```
You must be logged in to the server (Unauthorized)
```
or
```
Authentication required (HTML /login response)
```

### Root Causes

1. Jenkins user (`jenkins`) was not using the same kubeconfig as `ubuntu`
2. Kubeconfig referenced certificate **file paths**:
   ```yaml
   client-certificate: /home/ubuntu/.minikube/...
   ```
3. Jenkins user had no permission to read `/home/ubuntu/.minikube`

### Fix

- Export kubeconfig with embedded certs:
  ```bash
  kubectl config view --raw --flatten > minikube-kubeconfig.yaml
  ```
- Upload kubeconfig as **Secret file** in Jenkins
- Use it via:
  ```groovy
  withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')])
  ```

---

## 3. Jenkins HTML /login Error

### Error

```
couldn't get current server API group list:
<html> ... /login ...
```

### Meaning

- `kubectl` was NOT talking to Kubernetes
- It was hitting a web endpoint (wrong kubeconfig / context)

### Fix

- Verified `server:` in kubeconfig:
  ```yaml
  server: https://192.168.49.2:8443
  ```
- Ensured Jenkins could reach Minikube network

---

## 4. RBAC Introduction (Least Privilege)

### Goal

- Jenkins should deploy **only** to `default` namespace
- No cluster-admin access

### Resources Created

#### ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: default
```

#### Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deployer
  namespace: default
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["pods", "events"]
  verbs: ["get", "list", "watch"]
```

#### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deployer-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: default
roleRef:
  kind: Role
  name: jenkins-deployer
  apiGroup: rbac.authorization.k8s.io
```

---

## 5. Authentication vs Authorization Confusion

### Key Lesson

| Error Type | Meaning |
|----------|--------|
| Unauthorized | Authentication failed (token / CA / kubeconfig) |
| Forbidden | Auth OK, RBAC denied |

### Diagnostic Command

```bash
kubectl auth whoami
```

Expected:
```
system:serviceaccount:default:jenkins
```

---

## 6. Short-Lived Token Problem

### What We Did Initially

```bash
kubectl create token jenkins -n default
```

### Problem

- Token expires (~1 hour)
- Jenkins pipelines started failing randomly

### Lesson

> `kubectl create token` is **short-lived by design**

---

## 7. Long-Lived Token for Jenkins (Correct Approach)

### Secret Definition

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: jenkins
type: kubernetes.io/service-account-token
```

### Major Bug Found

Secret was created with **wrong type**:

```yaml
type: kubernetes.io/service-account.name   ❌
```

### Result

- Secret existed
- But `data:` was empty
- No token generated

### Fix

- Correct `type` to:
  ```yaml
  kubernetes.io/service-account-token
  ```

After reapplying, Kubernetes populated:
```yaml
data:
  token:
  ca.crt:
  namespace:
```

---

## 8. Building Final Jenkins Kubeconfig

Key rules:
- Token → **plain text**
- CA → **base64**
- No client cert paths

```yaml
apiVersion: v1
kind: Config
clusters:
- name: minikube
  cluster:
    server: https://192.168.49.2:8443
    certificate-authority-data: <base64-ca>
users:
- name: jenkins
  user:
    token: <token>
contexts:
- name: jenkins-context
  context:
    cluster: minikube
    user: jenkins
    namespace: default
current-context: jenkins-context
```

Verified with:
```bash
kubectl auth whoami
kubectl auth can-i update deployment/go-db-app -n default
```

---

## 9. Rollout & Rollback Logic

### Initial Bug

Rollback did NOT execute even though rollout failed.

### Root Cause

```bash
set -e
if ! kubectl rollout status ...; then
  rollback
fi
```

`set -e` caused shell to exit **before** `if` block.

### Fix (Correct Pattern)

```bash
set +e
kubectl rollout status ...
STATUS=$?
set -e

if [ $STATUS -ne 0 ]; then
  kubectl rollout undo ...
  exit 1
fi
```

---

## 10. progressDeadlineSeconds Confusion

### Observation

- YAML updated to:
  ```yaml
  progressDeadlineSeconds: 120
  ```
- Jenkins still waited 600s

### Reason

Jenkins was using:
```bash
kubectl set image
```

This updates ONLY the image, not other spec fields.

### Real-World Lesson

> `kubectl set image` ≠ `kubectl apply`

### Fix

One-time patch:
```bash
kubectl patch deployment go-db-app -p '{"spec":{"progressDeadlineSeconds":120}}'
```

Or move to declarative deploys / GitOps.

---

## 11. Why Argo CD Exists (Key Insight)

This entire experience demonstrated:
- Config drift
- Imperative deploy limitations
- Human error in CI pipelines

**Argo CD solves exactly this problem** by:
- Making Git the source of truth
- Continuously reconciling cluster state

---

## 12. Final Architecture Achieved

- Jenkins:
  - builds image
  - pushes image
  - deploys with RBAC
- Kubernetes:
  - namespace-scoped access
  - rollback-safe deployments
- Security:
  - no cluster-admin
  - stable auth
  - predictable behavior

---

## 13. Key Takeaways

1. Authentication ≠ Authorization
2. CI systems need long-lived credentials or GitOps
3. `set -e` can silently break rollback logic
4. Imperative deploys cause config drift
5. Argo CD exists for a reason

---

**Status:** ✅ Stable, secure, production-aligned setup  
