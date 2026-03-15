
# Making Jenkins a Non-Admin Kubernetes User
(ServiceAccount + RBAC + Long-Lived Token)

## Objective

This document explains **how Jenkins was configured as a non-admin Kubernetes user**, allowed to perform **only Deployment-related actions**, using:

- A **ServiceAccount**
- **Role + RoleBinding (RBAC)**
- A **long‑lived ServiceAccount token** created via a Secret
- A dedicated **kubeconfig**

This is a **real-world, production-grade pattern** used widely before or alongside GitOps tools like Argo CD.

---

## 1. Core Principle (Most Important)

> **Jenkins is non-admin because it authenticates as a ServiceAccount,  
> and that ServiceAccount is restricted by RBAC.**

Nothing else makes Jenkins “admin” or “non-admin”.

---

## 2. Authentication vs Authorization

| Layer | Question | Controlled By |
|----|----|----|
| Authentication | Who are you? | kubeconfig + token |
| Authorization | What can you do? | Role / RoleBinding |
| Context | Where does it apply? | kubeconfig context |

---

## 3. Step 1 — Create a ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: default
```

This creates the identity:

```
system:serviceaccount:default:jenkins
```

Jenkins will authenticate as this identity.

---

## 4. Step 2 — Define Least-Privilege Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deployer
  namespace: default
rules:
- apiGroups: ["apps"]
  resources:
    - deployments
    - replicasets
  verbs:
    - get
    - list
    - watch
    - create
    - update
    - patch

- apiGroups: [""]
  resources:
    - pods
    - events
  verbs:
    - get
    - list
    - watch
```

This Role allows Jenkins to deploy and monitor applications, **nothing more**.

---

## 5. Step 3 — Bind Role to ServiceAccount

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

Now only the Jenkins ServiceAccount has these permissions.

---

## 6. Step 4 — Why `kubectl create token` Is Not Enough

```bash
kubectl create token jenkins
```

- Tokens are **short-lived**
- Pipelines break after expiry
- Not suitable for CI/CD

---

## 7. Step 5 — Create a Long-Lived Token Using a Secret

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

Kubernetes automatically injects:

```yaml
data:
  token:
  ca.crt:
  namespace:
```

This token does **not expire**.

---

## 8. Step 6 — Extract Token

```bash
kubectl get secret jenkins-token -n default   -o jsonpath='{.data.token}' | base64 -d
```

---

## 9. Step 7 — Create Jenkins kubeconfig

```yaml
apiVersion: v1
kind: Config

clusters:
- name: minikube
  cluster:
    server: https://<API_SERVER>:8443
    certificate-authority-data: <BASE64_CA>

users:
- name: jenkins
  user:
    token: <LONG_LIVED_TOKEN>

contexts:
- name: jenkins-context
  context:
    cluster: minikube
    user: jenkins
    namespace: default

current-context: jenkins-context
```

This kubeconfig ensures Jenkins authenticates **only** as the ServiceAccount.

---

## 10. Step 8 — Upload kubeconfig to Jenkins

- Jenkins → Manage Jenkins → Credentials
- Kind: **Secret file**
- Credential ID: `kubeconfig-jenkins`

Usage in Jenkinsfile:

```groovy
withCredentials([
  file(credentialsId: 'kubeconfig-jenkins', variable: 'KUBECONFIG')
]) {
  sh 'kubectl get deployments'
}
```

---

## 11. Verification

### Identity check
```bash
kubectl auth whoami
```
Expected:
```
system:serviceaccount:default:jenkins
```

### Permission check
```bash
kubectl auth can-i update deployment -n default
# yes

kubectl auth can-i delete namespace
# no
```

---

## 12. Why This Is Secure

| Aspect | Result |
|----|----|
| Admin access | ❌ None |
| Scope | Namespace-only |
| Token expiry | ❌ None |
| Blast radius | Minimal |

---

## 13. Key Takeaway

> **Jenkins is non-admin because it authenticates as a ServiceAccount,  
> and RBAC limits that ServiceAccount.**

The kube-context only selects which identity is used.

---

## 14. Next Step

- Convert deployments to `kubectl apply`
- Or move to GitOps (Argo CD)

---

**Status:** ✅ Secure, least-privilege Jenkins → Kubernetes integration
