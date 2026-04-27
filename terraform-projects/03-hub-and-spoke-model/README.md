# 🚀 Azure App Service + AKS Observability & Secure Architecture

## 📌 Overview

This project demonstrates a production-style cloud setup where a frontend application hosted on Azure App Service securely communicates with a backend deployed in Azure Kubernetes Service (AKS), with full observability using Azure Monitor and Application Insights.

The focus is on:

* Secure communication using private networking
* Secret management using Key Vault + Managed Identity
* Observability using logs, metrics, alerts, and dashboards
* Infrastructure provisioning using Terraform

---

## 🏗️ Architecture

```
User → App Service (Frontend)
        ↓
   VNet Integration
        ↓
   AKS (Backend API)
        ↓
   (Future: Database)

Monitoring Layer:
App Insights + Log Analytics + Alerts + Workbooks
```

---

## 🔐 Security Design

### 1. Managed Identity + Key Vault

* App Service uses **User Assigned Managed Identity**
* Secrets (API endpoints, configs) are stored in **Azure Key Vault**
* Access is granted using **RBAC (Key Vault Secrets User role)**

Example:

```
@Microsoft.KeyVault(SecretUri=https://<kv-name>.vault.azure.net/secrets/API-BASE-URL)
```

---

### 2. Private Networking

* App Service uses **VNet Integration**
* AKS is deployed inside a **private VNet**
* Communication happens via **private IP (internal Load Balancer)**

Key concepts used:

* VNet Peering
* NSG rules for controlled traffic
* Private DNS for service resolution

---

### 3. Key Vault Private Endpoint

* Public access disabled (`default_action = Deny`)
* Access only via **Private Endpoint**
* DNS resolution handled via:

  * `privatelink.vaultcore.azure.net`

---

## 📊 Observability Setup

### Application Insights Enabled

* Auto-collection enabled for:

  * Requests
  * Dependencies
  * Exceptions
  * Performance

---

### 🔍 Key KQL Queries

#### 1. Request Volume

```kusto
requests
| where name !contains "health"
| summarize count() by bin(timestamp, 5m)
```

---

#### 2. Failure Rate

```kusto
requests
| where name !contains "health"
| summarize 
    total = count(),
    failures = countif(success == false)
    by bin(timestamp, 5m)
| extend failureRate = failures * 100.0 / total
```

---

#### 3. Slow Requests (>2 sec)

```kusto
requests
| where name !contains "health"
| extend durationSec = duration / 1000.0
| where durationSec > 2
| project name, durationSec, resultCode
| order by durationSec desc
```

---

#### 4. 5xx Errors

```kusto
requests
| where toint(resultCode) >= 500
| summarize count() by name
```

---

#### 5. Dependency Latency (App → AKS)

```kusto
dependencies
| summarize avg(duration) by target
| order by avg_duration desc
```

---

## 🚨 Alerts Configured

| Alert Type   | Condition         | Purpose                   |
| ------------ | ----------------- | ------------------------- |
| Failure Rate | > 5%              | Detect system degradation |
| 5xx Errors   | > threshold count | Catch backend failures    |
| Latency      | > 2 seconds       | Detect slow performance   |
| No Traffic   | count == 0        | Detect downtime           |

---

## 📊 Dashboard (Workbook)

A custom Azure Workbook was created with:

* Request volume (time-based)
* Failure rate trend
* P95 latency
* Top slow endpoints
* Top failing endpoints

---

## ⚙️ Terraform Setup

### Key Resources

* `azurerm_linux_web_app`
* `azurerm_linux_web_app_slot`
* `azurerm_service_plan`
* `azurerm_application_insights`
* `azurerm_key_vault`
* `azurerm_private_endpoint`
* `azurerm_role_assignment`

---

### Highlights

* Modular Terraform structure
* Use of `archive_file` for deployment
* Slot-based deployment (staging → production)
* Managed Identity integration
* RBAC-based Key Vault access

---

## 🔄 Deployment Strategy

* Code deployed to **staging slot**
* Tested using:

  * `/health`
  * `/version`
  * `/test-ai`
* Swapped to production after validation

---

## 🧪 Debugging Flow (Real-world approach)

```
Alert triggered
   ↓
Check Workbook Dashboard
   ↓
Inspect requests table
   ↓
Analyze dependencies (AKS calls)
   ↓
Check traces / logs
   ↓
Identify root cause
```

---

## 📚 Key Learnings

* Difference between:

  * VNet Integration vs Private Endpoint
* Importance of filtering noise (health checks) in monitoring
* KQL data types (duration handling)
* Managed Identity simplifies secret management
* Alerts should be meaningful, not noisy
* Observability = logs + metrics + tracing + alerts

---

## 🚀 Future Improvements

* Instrument AKS backend using OpenTelemetry
* Add database layer with monitoring
* Implement retry + circuit breaker patterns
* Setup backup & disaster recovery
* Introduce CI/CD pipeline (GitHub Actions / Azure DevOps)

---

## 📌 Summary

This project demonstrates:

* Secure cloud-native architecture
* End-to-end observability setup
* Real-world debugging workflow
* Infrastructure as Code using Terraform

---
