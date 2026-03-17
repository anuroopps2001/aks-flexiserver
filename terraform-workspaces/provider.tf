terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

#   backend "azurerm" {
#     resource_group_name  = "tf-state-rg"
#     storage_account_name = "youruniquestorageacct" # Must be globally unique
#     container_name       = "tfstate"
#     key                  = "go-db.terraform.tfstate"
#   }
}

provider "azurerm" {
  features {}
}