terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.19.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
  }
}

provider "azurerm" {
  subscription_id = "<placeholder>"
  features {
  }
}

data "azurerm_client_config" "current" {}