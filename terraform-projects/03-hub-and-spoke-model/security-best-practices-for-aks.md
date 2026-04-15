### 1. Managed Infrastructure
**We are using AKS Managed Node Pools. Azure handles the underlying Ubuntu or Azure Linux host OS patching, the Kubelet version, and the container runtime.**

### 2. No Direct SSH Access
**We haven't enabled SSH keys for our node pools. If you need to "jump" into a node, we would use az aks command invoke or a debug pod, rather than opening Port 22.**

### 3. Identity & Least Privilege (Workload Identity)
* We are using Azure `Workload Identity` and `Managed Identities`.

**Instead of static secrets, our pods use a federated identity to talk to Key Vault.**

**We also applied the `Network Contributor` role to a specific `Managed Identity`, following the Principle of Least Privilege.**

### 4. Private Cluster Endpoint
**We explicitly set `private_cluster_enabled = true` in our Terraform. our AKS API server has no public IP and is only accessible via your VNet/Runner.**

### 5. Secret Management & Rotation
* We are using `Azure Key Vault` with the `Secrets Store CSI Driver`.

**We enabled `secret_rotation_enabled = true` and `secret_rotation_interval = "2m"`.**

**This ensures that if you update a secret in Key Vault, it automatically updates inside the AKS pods without a restart.**

6. Private Connectivity (The "Envoy" Layer)

**Using an `Internal Load Balancer (ILB) and Envoy Gateway`. Traffic from the internet hits the `Application Gateway (WAF)`, then travels over a private IP (10.x.x.x) to Envoy. Nothing is exposed to the public internet except the WAF**