# 🚀 AKS ↔ GCP Cloud SQL Secure Integration (Workload Identity + Cloud SQL Proxy)

## 📌 Overview

This project demonstrates a secure cross-cloud architecture where an application running in Azure Kubernetes Service (AKS) connects to a Google Cloud SQL PostgreSQL instance using:

- Cloud SQL Proxy
- IAM-based authentication (no passwords)
- Azure Workload Identity + GCP Workload Identity Federation
- ArgoCD + Kustomize for GitOps deployment

---

## 🧠 Architecture

AKS Pod
 ↓
Kubernetes Service Account (KSA)
 ↓
Azure Workload Identity
 ↓
OIDC Token
 ↓
GCP Workload Identity Federation
 ↓
GCP Service Account (cloudsql-sa)
 ↓
Cloud SQL Proxy
 ↓
Cloud SQL PostgreSQL

---

## 🏗️ Components & Why They Exist

### 1️⃣ AKS Cluster & Node Pool
Hosts workloads and provides compute.

### 2️⃣ Kubernetes Deployment
Runs Go app + Cloud SQL Proxy sidecar.

### 3️⃣ Cloud SQL
Managed PostgreSQL database in GCP.

### 4️⃣ Cloud SQL Proxy
Handles IAM auth + secure connection.

### 5️⃣ Azure Workload Identity
Provides identity to pods without secrets.

### 6️⃣ GCP Workload Identity Federation
Allows Azure identities to access GCP.

### 7️⃣ GCP Service Account
Used for Cloud SQL access with role:
roles/cloudsql.client

### 8️⃣ External Account Config
Bridges Azure token → GCP token.

### 9️⃣ ArgoCD + Kustomize
Automated GitOps deployment.

---

## ⚙️ Implementation Steps

### Step 1: AKS Setup
Enable:
--enable-workload-identity
--enable-oidc-issuer

### Step 2: Cloud SQL
Create PostgreSQL instance with public IP enabled.

### Step 3: Service Account
Create and assign roles/cloudsql.client.

### Step 4: Workload Identity Federation
Create pool + provider.

### Step 5: Bind Identity
Bind AKS identity to GCP SA.

### Step 6: Kubernetes Service Account
Annotated with Azure client ID.

### Step 7: Deployment Config
Use serviceAccountName and label:
azure.workload.identity/use: "true"

### Step 8: Cloud SQL Proxy
Use:
--auto-iam-authn

### Step 9: External Account Config
Used for token exchange.

---

## 🔐 Security Improvements

- No DB passwords
- No JSON keys
- IAM-based authentication
- Short-lived tokens

---

## ⚠️ Limitation

Private IP does not work cross-cloud without VPN.
Using Public IP + Proxy instead.

---

## 🧪 Validation

kubectl logs <pod> -c cloud-sql-proxy

Expected:
Listening on 127.0.0.1:5432

---

## 🚀 Outcome

- Secure cross-cloud DB access
- No static credentials
- GitOps deployment working

---

## 📈 Future Improvements

- VPN between Azure and GCP
- Secret Manager
- Network policies

---

## 👨‍💻 Author

Anuroop P S
