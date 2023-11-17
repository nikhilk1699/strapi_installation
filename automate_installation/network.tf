resource "azurerm_virtual_network" "strapi-vnet" {
    name = "strap-vn"
    location = azurerm_resource_group.nstrapi_rg.location
    resource_group_name = azurerm_resource_group.nstrapi_rg.name
    address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = azurerm_resource_group.nstrapi_rg.name
  virtual_network_name = azurerm_virtual_network.strapi-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
 depends_on = [
    azurerm_virtual_network.strapi-vnet
  ]
}

resource "azurerm_public_ip" "strapi_pip" {
  name                = "strapi-public-ip"
  location            = azurerm_resource_group.nstrapi_rg.location
  resource_group_name = azurerm_resource_group.nstrapi_rg.name
  allocation_method   = "Static"
 depends_on = [ azurerm_resource_group.nstrapi_rg ]

}

resource "azurerm_network_interface" "strapi_interface" {
  name                = "strapi-interface"
  location            = azurerm_resource_group.nstrapi_rg.location
  resource_group_name = azurerm_resource_group.nstrapi_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.strapi_pip.id
  }
   depends_on = [
    azurerm_virtual_network.strapi-vnet,
    azurerm_public_ip.strapi_pip
  ]
}

resource "azurerm_network_security_group" "strapi_nsg" {
  name                = "strapi-SecurityGroup1"
  location            = azurerm_resource_group.nstrapi_rg.location
  resource_group_name = azurerm_resource_group.nstrapi_rg.name

  security_rule {
    name                       = "all-traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 depends_on = [ azurerm_virtual_network.strapi-vnet ]
}
resource "azurerm_subnet_network_security_group_association" "strapi_nsga" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.strapi_nsg.id
  depends_on = [
    azurerm_network_security_group.strapi_nsg]
}


