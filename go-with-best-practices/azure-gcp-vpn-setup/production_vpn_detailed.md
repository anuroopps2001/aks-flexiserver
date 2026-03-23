# 🚀 Production-Grade Cross-Cloud VPN: AKS ↔ GCP Cloud SQL (Private + IAM)

## 📌 Overview
This setup enables **secure private connectivity** between:
- Azure AKS (in VNet)
- GCP Cloud SQL (Private IP)

Using:
- Site-to-Site VPN (IPsec)
- BGP routing
- Cloud SQL Proxy with IAM

---

# 🏗️ Architecture

AKS → Azure VNet → Azure VPN Gateway ⇄ GCP VPN Gateway → GCP VPC → Cloud SQL (Private)

---

# 🌐 Network Plan

## Azure
- VNet: 10.0.0.0/16
- Subnet: 10.0.1.0/24
- GatewaySubnet: 10.0.255.0/27

## GCP
- VPC: 10.10.0.0/16
- Subnet: 10.10.1.0/24
- PSA Range: 172.30.32.0/20

---

# 🔧 Step-by-Step Setup

---

## 🟦 Azure Setup

### 1. Create VNet

az network vnet create \
  --name aks-vnet \
  --resource-group <RG> \
  --address-prefix 10.0.0.0/16 \
  --subnet-name aks-subnet \
  --subnet-prefix 10.0.1.0/24

---

### 2. Create Gateway Subnet

az network vnet subnet create \
  --name GatewaySubnet \
  --resource-group <RG> \
  --vnet-name aks-vnet \
  --address-prefix 10.0.255.0/27

---

### 3. Create Public IP

az network public-ip create \
  --resource-group <RG> \
  --name vpn-pip \
  --sku Standard

---

### 4. Create VPN Gateway

az network vnet-gateway create \
  --name azure-vpn-gateway \
  --resource-group <RG> \
  --public-ip-address vpn-pip \
  --vnet aks-vnet \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku VpnGw1

---

### 5. Create Local Network Gateway (GCP side)

az network local-gateway create \
  --name gcp-local \
  --resource-group <RG> \
  --gateway-ip-address <GCP_VPN_IP> \
  --local-address-prefixes 10.10.0.0/16 172.30.32.0/20

---

### 6. Create VPN Connection

az network vpn-connection create \
  --name azure-gcp-conn \
  --resource-group <RG> \
  --vnet-gateway1 azure-vpn-gateway \
  --local-gateway2 gcp-local \
  --shared-key MySharedKey

---

## 🟥 GCP Setup

---

### 1. Create VPC

gcloud compute networks create my-vpc --subnet-mode=custom

gcloud compute networks subnets create my-subnet \
  --network=my-vpc \
  --range=10.10.1.0/24 \
  --region=us-central1

---

### 2. Reserve PSA Range

gcloud compute addresses create psa-range \
  --global \
  --purpose=VPC_PEERING \
  --addresses=172.30.32.0 \
  --prefix-length=20 \
  --network=my-vpc

---

### 3. Create Cloud SQL with Private IP

gcloud sql instances create postgres-private \
  --network=my-vpc \
  --no-assign-ip

---

### 4. Create VPN Gateway

gcloud compute vpn-gateways create gcp-vpn \
  --network=my-vpc \
  --region=us-central1

---

### 5. Create External IP

gcloud compute addresses create gcp-vpn-ip --region=us-central1

---

### 6. Create Cloud Router (BGP)

gcloud compute routers create my-router \
  --network=my-vpc \
  --region=us-central1 \
  --asn=65001

---

### 7. Create VPN Tunnel

gcloud compute vpn-tunnels create tunnel-1 \
  --region=us-central1 \
  --peer-ip=<AZURE_PUBLIC_IP> \
  --ike-version=2 \
  --shared-secret=MySharedKey \
  --router=my-router

---

# 🔁 BGP Configuration

Azure BGP IP:
169.254.21.1

GCP BGP IP:
169.254.21.2

---

# ⚠️ Enable Route Export

gcloud compute networks update my-vpc \
  --bgp-routing-mode=global

Enable:
Export Custom Routes = TRUE

---

# 🔥 Firewall Rules

gcloud compute firewall-rules create allow-azure \
  --network=my-vpc \
  --allow tcp:5432 \
  --source-ranges=10.0.0.0/16

---

# 🧪 Testing

kubectl exec -it <pod> -- nc -zv 172.30.x.x 5432

---

# 🔑 Cloud SQL Proxy

--auto-iam-authn
--private-ip

---

# ✅ Outcome

✔ Private connectivity  
✔ IAM authentication  
✔ No public DB  
✔ Cross-cloud secure networking  

