location = "centralindia"

resource_groups = {
  "rg-hub-networking"  = { location = "centralindia" }
  "rg-spoke-workloads" = { location = "centralindia" }
}

hub_config = {
  name          = "vnet-hub-core"
  address_space = ["10.0.0.0/16"]
  rg            = "rg-hub-networking"
}

hub_subnets = {
  "snet-appgw" = {
    address_prefixes   = ["10.0.1.0/24"]
    service_delegation = null
    service_endpoints  = null
  }
  "snet-agw_new" = {
    address_prefixes   = ["10.0.2.0/24"]
    service_delegation = null
    service_endpoints  = null
  }

  "snet-appservice-integration" = {
    address_prefixes   = ["10.0.3.0/24"]
    service_delegation = "Microsoft.Web/serverFarms"
    service_endpoints  = ["Microsoft.KeyVault"]
  }
}

spoke_vnets = {
  "aks"              = { address_space = ["10.1.0.0/16"], rg = "rg-spoke-workloads" }
  "client-and-agent" = { address_space = ["10.2.0.0/16"], rg = "rg-spoke-workloads" }
  "data"             = { address_space = ["10.3.0.0/16"], rg = "rg-spoke-workloads" }
}

subnets = {
  "snet-aks" = {
    vnet_key          = "aks"
    address_prefixes  = ["10.1.1.0/24"]
    service_endpoints = ["Microsoft.KeyVault"]
  }
  "snet-db" = {
    vnet_key          = "data"
    address_prefixes  = ["10.3.1.0/24"]
    service_endpoints = [] # Because, for now not using with AzureKeyVault
  }

  "snet-client" = {
    vnet_key          = "client-and-agent"
    address_prefixes  = ["10.2.1.0/24"]
    service_endpoints = ["Microsoft.KeyVault"]
  }
}

kv_secrets = {
  "DB-HOST"        = "anuroop-psql-flex.postgres.database.azure.com"
  "DB-PORT"        = "5432"
  "DB-NAME"        = "aks-go-app-db"
  "DB-USERNAME"    = "psqladmin"
  "DOCKERHUB-USER" = "anuroop21"
  "DOCKERHUB-PASS" = "changeme@2108"
  "API-BASE-URL"   = "http://10.1.1.6"
}