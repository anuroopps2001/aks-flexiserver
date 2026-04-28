# 1. Generate the SAS specifically for a Container
data "azurerm_storage_account_sas" "name" {
  connection_string = var.storage_connection_string
  https_only        = true

  # Resource types the SAS will apply to
  resource_types {
    service   = true # Required for account-level operations
    container = true # Access to containers
    object    = true # Access to individual blobs
  }

  # Services to enable (e.g., just Blobs, or include Files/Queues)
  services {
    blob  = true
    file  = true
    table = false
    queue = false
  }

  start  = var.start_time
  expiry = var.expiry_time

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }

  # to allow access of SAS on specific IP Address
  # ip_addresses = <any_ip_to_access_SAS>
}