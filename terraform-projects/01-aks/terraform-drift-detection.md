# Terraform Drift Handling Guide

## What is Terraform Drift?

**Terraform Drift** occurs when you make manual changes in the Azure Portal (or outside Terraform).

- Azure becomes the **actual state**
- Terraform `.tf` files remain the **expected state**

If you run `terraform apply` without fixing drift, Terraform will try to **revert your manual changes**.

---

## Step 1: Detect the Drift

Run a refresh-only plan:

```bash
terraform plan -refresh-only
```

### What to look for:
- `~` → Updated resources
- `-` → Deleted resources

These indicate changes made outside Terraform.

---

## Step 2: Update the State (Quick Fix)

If you're okay with the manual changes:

```bash
terraform apply -refresh-only
```

### What this does:
- Updates `terraform.tfstate`
- **Does NOT update your `.tf` files**

---

## Step 3: Update Your Code (Real Fix)

If you skip this step, Terraform will try to revert changes in the next apply.

### Example (AKS resource):

```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  # ... other config ...

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
}
```

---

## Alternative: `terraform show` Strategy (More Accurate)

If the plan output is messy:

### Steps:
```bash
terraform apply -refresh-only
terraform show -no-color > current_state.txt
```

- Open `current_state.txt`
- Find the relevant resource
- Copy the correct configuration into your `.tf` files

---

## Final Sync

- Update all `.tf` files to match `terraform.tfstate`
- Run:

```bash
terraform apply
```

### Expected outcome:
- No changes → ✅ Perfect sync
- Changes detected → Fix or import resources

---

## When Terraform Wants to Create Existing Resources

Example output:

```bash
Plan: 2 to add, 1 to change, 0 to destroy.
```

### Interpretation:
- Terraform doesn’t know these resources exist
- You must **import them manually**

---

## Example Terraform Plan Output

```bash
# azurerm_kubernetes_cluster.aks will be updated in-place
~ resource "azurerm_kubernetes_cluster" "aks" {
    id   = "/subscriptions/.../managedClusters/aks-private-india"
    name = "aks-private-india"

  ~ default_node_pool {
      name = "default"

    - upgrade_settings {
        drain_timeout_in_minutes      = 0 -> null
        max_surge                     = "10%" -> null
        node_soak_duration_in_minutes = 0 -> null
      }
  }
}

# azurerm_postgresql_flexible_server.db will be created
+ resource "azurerm_postgresql_flexible_server" "db" {
    name       = "pg-flex-india"
    location   = "centralindia"
    sku_name   = "GP_Standard_D2s_v3"
    storage_mb = 32768
    version    = "13"
}

# azurerm_subnet.gateway_subnet will be created
+ resource "azurerm_subnet" "gateway_subnet" {
    name                 = "GatewaySubnet"
    address_prefixes     = ["10.1.255.0/27"]
    virtual_network_name = "vnet-aks"
}
```

---

## Importing Existing Resources

Even if `.tf` files exist, Terraform may not track resources until imported.

### Commands used:

```bash
terraform import azurerm_postgresql_flexible_server.db \
/subscriptions/.../flexibleServers/pg-flex-india

terraform import azurerm_subnet.gateway_subnet \
/subscriptions/.../virtualNetworks/vnet-aks/subnets/GatewaySubnet
```

---

## Terraform Import Syntax

```bash
terraform import [Address in Code] [ID in Azure]
```

### Breakdown:

- **[Address in Code]**
  ```bash
  azurerm_subnet.gateway_subnet
  ```
  Refers to the resource block in `.tf`

- **[ID in Azure]**
  - Full Azure Resource ID
  - Unique identifier for the resource

---

## Key Insight (Don’t Ignore This)

You’re treating Terraform like a deployment tool. It’s not.

It’s a **state reconciliation engine**.

If:
- State ≠ Code → Terraform will act
- Azure ≠ State → Terraform will drift
- You skip code updates → Terraform will undo your work

---

## Practical Rule

After any manual change:

1. `terraform plan -refresh-only`
2. `terraform apply -refresh-only`
3. Update `.tf`
4. `terraform apply`

Skip step 3 → you will get burned later.
