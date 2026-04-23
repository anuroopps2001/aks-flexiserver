terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.67.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.8.0" # Use a modern version
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}

  storage_use_azuread = true
}

provider "random" {}

provider "azuread" {

}