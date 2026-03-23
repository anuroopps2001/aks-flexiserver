# 🚀 Elite-Level Cross-Cloud Networking: AKS ↔ GCP Cloud SQL (Private, IAM, S2S VPN)

---

## 📌 Overview

This project implements **secure, production-grade cross-cloud connectivity** between:

- Azure Kubernetes Service (AKS)
- Google Cloud SQL (PostgreSQL with Private IP)

Using:

- Site-to-Site VPN (IPsec + BGP)
- Private Service Access (GCP)
- Cloud SQL Proxy with IAM authentication

---

## 🎯 Design Goals

- ❌ No public database exposure
- ❌ No static credentials
- ✔ Private connectivity via VPN
- ✔ Identity-based authentication
- ✔ Scalable multi-cloud architecture

---

## 🏗️ Architecture

AKS Pod  
↓  
Cloud SQL Proxy (IAM Auth)  
↓  
Azure VNet  
↓  
Azure VPN Gateway  
⇄ IPsec Tunnel ⇄  
GCP VPN Gateway  
↓  
GCP VPC  
↓  
Private Service Access  
↓  
Cloud SQL  

---

## 🌐 Network Plan

### Azure
- VNet: 10.0.0.0/16
- AKS Subnet: 10.0.1.0/24
- GatewaySubnet: 10.0.255.0/27

### GCP
- VPC: 10.10.0.0/16
- Subnet: 10.10.1.0/24
- PSA Range: 172.30.32.0/20

---

## 🔁 BGP Configuration

| Side | BGP IP | ASN |
|------|--------|-----|
| Azure | 169.254.21.1 | 65515 |
| GCP   | 169.254.21.2 | 65001 |

---

## 🔧 Full Setup Steps

---

### 🟦 Azure Setup

#### Create VNet
```bash
az network vnet create   --name aks-vnet   --resource-group <RG>   --address-prefix 10.0.0.0/16   --subnet-name aks-subnet   --subnet-prefix 10.0.1.0/24
```

#### Gateway Subnet
```bash
az network vnet subnet create   --name GatewaySubnet   --resource-group <RG>   --vnet-name aks-vnet   --address-prefix 10.0.255.0/27
```

#### VPN Gateway
```bash
az network vnet-gateway create   --name azure-vpn-gateway   --resource-group <RG>   --vnet aks-vnet   --gateway-type Vpn   --vpn-type RouteBased   --sku VpnGw1
```

---

### 🟥 GCP Setup

#### VPC
```bash
gcloud compute networks create my-vpc --subnet-mode=custom
```

#### Subnet
```bash
gcloud compute networks subnets create my-subnet   --network=my-vpc   --range=10.10.1.0/24   --region=us-central1
```

#### PSA Range
```bash
gcloud compute addresses create psa-range   --global   --purpose=VPC_PEERING   --addresses=172.30.32.0   --prefix-length=20   --network=my-vpc
```

---

## 🔥 Critical Concepts

### 1. Routing vs Connectivity
VPN up ≠ traffic works  
Routes must exist on both sides  

### 2. Private Service Access
Cloud SQL uses:
```
172.30.32.0/20
```
Not your subnet.

### 3. Route Export
Must enable:
```
Export Custom Routes
```

---

## 🧪 Validation

### Check connectivity
```bash
nc -zv 172.30.x.x 5432
```

### Check routes
```bash
gcloud compute routes list
az network route-table route list
```

---

## 🚨 Real Issues Faced (Important)

- VPN up but no traffic → missing route export
- Wrong assumption → Cloud SQL in subnet
- IAM vs DB permissions confusion
- Proxy vs direct DB misunderstanding

---

## 🧠 Key Learnings

- Networking = routing + firewall + identity
- Managed services use separate CIDR
- IAM != DB permissions
- Debugging requires layer-by-layer validation

---

## 🚀 Resume Bullet

Implemented cross-cloud private connectivity between AKS and GCP Cloud SQL using Site-to-Site VPN with BGP routing, Private Service Access, and IAM-based authentication, eliminating public exposure and static credentials.

---

## 📌 Outcome

✔ Fully private DB access  
✔ Secure IAM authentication  
✔ Cross-cloud production architecture  

