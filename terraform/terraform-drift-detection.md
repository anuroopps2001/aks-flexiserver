**"Terraform Drift." Your manual changes in the Azure Portal are now "reality," but your Terraform code (the "blueprint") hasn't been updated to match.**

If you run `terraform apply` right now, Terraform will likely try to undo your manual changes to make Azure match your old code. Here is the safest workflow to sync them back up.

#### Step 1: Detect the Drift
Run a "refresh-only" plan. This tells Terraform to go check Azure and show you exactly what has changed since the last time it ran.
```bash
$ terraform plan -refresh-only
```
- **What to look for**: Look for lines starting with ~ (update) or - (delete). These represent the manual changes you made in the portal.

### Step 2: Update the State (The Quick Fix)
If you are happy with these changes and want Terraform to stop flagging them as "external," run:

```bash
terraform apply -refresh-only
```
This updates your `terraform.tfstate` file. However, it does NOT update your .tf files.

#### Step 3: Update your Code Manually (The Real Fix)
If you don't update your .tf files, the next time you run a normal terraform apply, Terraform will try to delete all the drifts detected.

To prevent this, you need to add the detected drift blocks to your configuration. For example, in your AKS resource:
```bash
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

**OR**

#### The `terraform show` Strategy (Most Accurate)
If the plan output is too messy, you can see exactly how the resource looks in its current "perfect" state in Azure:

Run `terraform apply -refresh-only` first (this updates your state file).

Run `terraform show -no-color > current_state.txt`.

Open `current_state.txt`, find the drift section, and copy the clean HCL code directly into your required .tf file.



#### Make the changes manually for the respective resource
Update all the .tf files to match the terraform.tfstate file and run `terraform apply`.

If you no changes to be made, that's a perfect sign. 

However, if you see resources to be created, then import those resources manually using `terraform import`

```bash
$ terraform plan

azurerm_resource_group.rg_south: Refreshing state... [id=/subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/rg-aks-southindia]
azurerm_resource_group.rg_central: Refreshing state... [id=/subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/rg-db-centralindia]
azurerm_virtual_network.vnet_south: Refreshing state... [id=/subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/rg-aks-southindia/providers/Microsoft.Network/virtualNetworks/vnet-aks]
.
.
.
.

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
  ~ update in-place

Terraform will perform the following actions:

  # azurerm_kubernetes_cluster.aks will be updated in-place
  ~ resource "azurerm_kubernetes_cluster" "aks" {
        id                                  = "/subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/rg-aks-southindia/providers/Microsoft.ContainerService/managedClusters/aks-private-india"
        name                                = "aks-private-india"
        tags                                = {}
        # (37 unchanged attributes hidden)

      ~ default_node_pool {
            name                          = "default"
            tags                          = {}
            # (31 unchanged attributes hidden)

          - upgrade_settings {
              - drain_timeout_in_minutes      = 0 -> null
              - max_surge                     = "10%" -> null
              - node_soak_duration_in_minutes = 0 -> null
                # (1 unchanged attribute hidden)
            }
        }

        # (6 unchanged blocks hidden)
    }

  # azurerm_postgresql_flexible_server.db will be created
  + resource "azurerm_postgresql_flexible_server" "db" {
      + administrator_login           = "psqladmin"
      + administrator_password        = (sensitive value)
      + administrator_password_wo     = (write-only attribute)
      + auto_grow_enabled             = false
      + backup_retention_days         = (known after apply)
      + delegated_subnet_id           = "/subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/rg-db-centralindia/providers/Microsoft.Network/virtualNetworks/vnet-db/subnets/snet-db-flex"
      + fqdn                          = (known after apply)
      + geo_redundant_backup_enabled  = false
      + id                            = (known after apply)
      + location                      = "centralindia"
      + name                          = "pg-flex-india"
      + private_dns_zone_id           = "/subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/rg-db-centralindia/providers/Microsoft.Network/privateDnsZones/private.postgres.database.azure.com"
      + public_network_access_enabled = false
      + resource_group_name           = "rg-db-centralindia"
      + sku_name                      = "GP_Standard_D2s_v3"
      + storage_mb                    = 32768
      + storage_tier                  = (known after apply)
      + version                       = "13"
      + zone                          = "1"

      + authentication (known after apply)
    }

  # azurerm_subnet.gateway_subnet will be created
  + resource "azurerm_subnet" "gateway_subnet" {
      + address_prefixes                              = [
          + "10.1.255.0/27",
        ]
      + default_outbound_access_enabled               = true
      + id                                            = (known after apply)
      + name                                          = "GatewaySubnet"
      + private_endpoint_network_policies             = "Disabled"
      + private_link_service_network_policies_enabled = true
      + resource_group_name                           = "rg-aks-southindia"
      + virtual_network_name                          = "vnet-aks"
    }

Plan: 2 to add, 1 to change, 0 to destroy.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── 

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

Below I had to import 2 resourcs, even though .tf files had these configurations present 
```bash
$ terraform import azurerm_postgresql_flexible_server.db /subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/rg-db-centralindia/providers/Microsoft.DBforPostgreSQL/flexibleServers/pg-flex-india

$ terraform import azurerm_subnet.gateway_subnet /subscriptions/3c744587-46e1-4a41-b95f-3bca3fd5e622/resourceGroups/rg-aks-southindia/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/GatewaySubnet
```


The Syntax Breakdown
The `terraform import` command always follows this pattern:
```bash
$ terraform import [Address in Code] [ID in Azure]
```
`[Address in Code]`: This is the local name you gave the resource in your .tf file (e.g., azurerm_subnet.gateway_subnet). It tells Terraform, "I want to associate the following ID with this block of code.

`[ID in Azure]`: This is the Resource ID. It is a unique string that points to exactly one object in the entire Microsoft Azure ecosystem.