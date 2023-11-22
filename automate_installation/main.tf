terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.80.0"
    }
  }
}
provider "azurerm" {
  features{}
}

resource "azurerm_resource_group" "nstrapi_rg" {
    name = "nstrapi-rg"
    location = " East US"
}

