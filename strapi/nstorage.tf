resource "azurerm_storage_account" "strapi_storage" {
  name                     = "strapistroage"
  resource_group_name      = azurerm_resource_group.nstrapi_rg.name
  location                 = azurerm_resource_group.nstrapi_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
}
resource "azurerm_storage_container" "strapi_container" {
  name                  = "secretfile"
  storage_account_name  = azurerm_storage_account.strapi_storage.name
  container_access_type = "private"
}





