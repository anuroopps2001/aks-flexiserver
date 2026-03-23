# 🚀 Production-Grade Cross-Cloud Networking: AKS ↔ GCP Cloud SQL (Private, IAM, S2S VPN)

## 📌 Overview
This project implements **secure, private, production-grade connectivity** between:
- **Azure Kubernetes Service (AKS)** in Azure VNet
- **Google Cloud SQL (PostgreSQL)** with **Private IP only**

Connectivity is established via **Site-to-Site (S2S) VPN**, and authentication is handled using **IAM via Cloud SQL Proxy** (no static DB passwords).

---

## 🎯 Goals
- ❌ No public exposure of database
- ❌ No static credentials
- ✔ Private networking (VPN)
- ✔ Identity-based access (IAM)
- ✔ Production-ready architecture

---

## 🏗️ Architecture

```
AKS Pod
   ↓
Cloud SQL Proxy (IAM Auth)
   ↓
Azure VNet (10.0.0.0/16)
   ↓
Azure VPN Gateway
   ⇄ IPsec Tunnel ⇄
GCP VPN Gateway
   ↓
GCP VPC (10.10.0.0/16)
   ↓
Private Service Access (172.30.32.0/20)
   ↓
Cloud SQL (Private IP)
```

---

## 🌐 Network Design

### 🔵 Azure
| Component | CIDR |
|----------|------|
| VNet | 10.0.0.0/16 |
| AKS Subnet | 10.0.1.0/24 |
| GatewaySubnet | 10.0.255.0/27 |
| Pod CIDR | 10.244.0.0/16 |

### 🔴 GCP
| Component | CIDR |
|----------|------|
| VPC | 10.10.0.0/16 |
| Subnet | 10.10.1.0/24 |
| PSA Range | 172.30.32.0/20 |

> ⚠️ Cloud SQL uses **Private Service Access range**, not subnet.

---

## 🔗 Connectivity Setup

### Azure
- VNet + Subnets
- VPN Gateway (Route-based)
- Public IP

### GCP
- VPC + Subnet
- Cloud VPN Gateway
- Cloud Router (BGP)
- Private Service Access

---

## 🔄 Routing (CRITICAL)

### Azure → GCP
```
10.10.0.0/16 → VPN Gateway
172.30.32.0/20 → VPN Gateway
```

### GCP → Azure
```
10.0.0.0/16 → VPN Tunnel
```

---

## ⚠️ MUST: Export Custom Routes

Enable in GCP VPC:
```
Export Custom Routes = TRUE
```

This ensures:
```
172.30.32.0/20 (Cloud SQL range) is advertised
```

---

## 🔐 Security Configuration

### GCP Firewall
- Allow: `10.0.0.0/16 → 172.30.32.0/20`
- Port: `5432`

### Azure NSG
- Allow outbound to `172.30.32.0/20:5432`

---

## 🧩 Application Design

### Pod Structure
- App Container
- Cloud SQL Proxy (sidecar)

### Proxy Config
```
--auto-iam-authn
--private-ip
--port=5432
<PROJECT>:<REGION>:<INSTANCE>
```

---

## 🔑 Authentication

- GCP IAM Service Account
- Token mounted (`gcp-token.json`)
- No DB password required

---

## 🧪 Validation Checklist

### 1. Network
```
nc -zv 172.30.x.x 5432
```

### 2. Proxy Logs
```
kubectl logs <pod> -c cloud-sql-proxy
```

### 3. DB Access
```
kubectl logs <pod> -c app
```

Expected:
```
DB connected successfully
```

---

## 🔍 Packet Flow (Simplified)

```
App → localhost:5432
 → Proxy
 → Node (NAT)
 → Azure VNet
 → VPN Gateway (IPsec)
 → GCP VPN Gateway
 → PSA Network
 → Cloud SQL
```

---

## 🚨 Troubleshooting

| Issue | Cause | Fix |
|------|------|-----|
| Timeout | Missing route | Check route tables |
| Connection refused | Firewall | Allow 5432 |
| Works public, fails private | Missing --private-ip | Add flag |
| VPN up but no traffic | No route export | Enable custom routes |
| Permission denied | DB role missing | Grant privileges |

---

## 🔒 Security Highlights

- ✔ No public DB access
- ✔ IAM-based auth
- ✔ Encrypted traffic (IPsec)
- ✔ Least privilege access
- ✔ Network isolation

---

## 🧠 Key Learnings

- VPN ≠ routing
- Cloud SQL uses PSA range
- Identity ≠ connectivity
- Route propagation is critical

---

## 🚀 Production Enhancements

- Hub-Spoke VNet design
- Azure Firewall integration
- Multi-env (dev/stage/prod)
- Observability (metrics + alerts)
- HA VPN setup

---

## ✅ Outcome

- Secure AKS → Cloud SQL connectivity
- Private networking enforced
- No credentials stored
- Enterprise-grade architecture

---

## 📎 Author Notes

This setup demonstrates real-world cross-cloud networking patterns combining:
- Azure networking
- GCP service networking
- Kubernetes
- IAM authentication

