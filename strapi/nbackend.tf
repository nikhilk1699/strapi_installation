terraform {
  backend "azurerm" {
    resource_group_name = "nstrapi-rg"
    storage_account_name = "strapistroage"
    container_name = "secretfile"
    key = "terraform.tfstate"
  }
}