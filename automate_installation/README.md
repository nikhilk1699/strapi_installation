# Terraform 
### main.tf
```
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
    location = "North Europe"
}
```
- terraform: This block is used to configure Terraform settings. In this case, it specifies the required providers.
- required_providers: Specifies the required providers for this configuration.
- azurerm: Specifies that the provider being used is azurerm.
- source: Specifies the source of the provider. In this case, it's from HashiCorp's official registry.
- version: Specifies the version of the azurerm provider that this configuration is compatible with.
- provider: This block configures the specific provider, in this case, azurerm.
- features: An empty block, meaning no specific features are enabled or disabled.
- resource Block: The resource block is used to define infrastructure resources. Azure Resource Group is created using the azurerm_resource_group resource type.
  the resource has a name ("nstrapi_rg") and is located in the "North Europe" region.

## storage.tf
```
resource "azurerm_storage_account" "strapi_storage" {
  name                     = "pstroage"
  resource_group_name      = azurerm_resource_group.nstrapi_rg.name
  location                 = azurerm_resource_group.nstrapi_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
}
resource "azurerm_storage_container" "strapi_container" {
  name                  = "secretfile"
  storage_account_name  = azurerm_storage_account.strapi_storage.name
  container_access_type = "private"
  depends_on = [ azurerm_storage_account.strapi_storage ]
}

resource "azurerm_storage_blob" "strapis_bob" {
  name                   = "terraform.tfstate"
  storage_account_name   = azurerm_storage_account.strapi_storage.name
  storage_container_name = azurerm_storage_container.strapi_container.name
  type                   = "Block"
  source                 = "terraform.tfstate"
  depends_on = [ azurerm_storage_container.strapi_container ]
}
```
- Azure Storage Account named "pstroage" in the specified Azure Resource Group (nstrapi_rg).
- It's set to use the "Standard" storage tier with Locally Redundant Storage (LRS) replication for redundancy.
- Azure Storage Container named "secretfile" within the previously defined Storage Account. The access type is set to "private," meaning only authorized users can access the container.
- depends_on attribute ensures that the Storage Account is created before creating the Storage Container.
- This block defines an Azure Storage Blob named "terraform.tfstate" within the specified Storage Container. It's set as a block type blob.
- The depends_on attribute ensures that the Storage Container is created before creating the Storage Blob. 

## network.tf
```
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
```

- The virtual network is named "strap-vn" with an address space of "10.0.0.0/16". This allows you to organize and isolate your resources within the specified IP range.
- Creates a subnet named "SubnetA" with an address prefix of "10.0.1.0/24" within defined virtual network. Subnets are useful for organizing resources and applying network security.
- Allocates a static public IP named "strapi-public-ip" in the specified location and resource group. This is typically associated with a resource that needs to be publicly accessible.
- Creates a network interface named "strapi-interface" in the specified location and resource group. It is associated with the previously defined subnet and public IP, allowing the associated resource to communicate with both private and public networks.
- Creates a network security group named "strapi-SecurityGroup1" with an inbound security rule allowing all traffic. Network security groups are used to control inbound and outbound traffic to network interfaces.
- Associates defined subnet with the network security group. This ensures that the security rules defined in the network security group are applied to the resources in the associated subnet.
- (depends_on): Specifies dependencies between resources to ensure that they are created in the correct order.
- Dynamic Allocation (private_ip_address_allocation): The network interface is configured for dynamic private IP address allocation.

### key.tf
```
resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "linuxkey" {
  filename = "linuxkey.pem"
  content  = tls_private_key.linux_key.private_key_pem
}
```
- The tls_private_key resource is used to generate a new RSA private key. The algorithm and rsa_bits attributes allow customization of the key's properties.
- The local_file resource creates a local file named "linuxkey.pem". The content of this file is set to the PEM-encoded RSA private key generated by the tls_private_key resource.
- A key size of 4096 bits is considered strong for RSA, providing a higher level of security. The private key should be handled securely, as it is a critical component for authentication and encryption.

## vm.tf
```
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "linuxvm"
  resource_group_name = azurerm_resource_group.nstrapi_rg.name
  location            = azurerm_resource_group.nstrapi_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "linuxusr"
  network_interface_ids = [
    azurerm_network_interface.strapi_interface.id,
  ]
  admin_ssh_key {
    username   = "linuxusr"
    public_key = tls_private_key.linux_key.public_key_openssh
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  provisioner "file" {
    source      = "script.sh"
    destination = "/home/linuxusr/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "ls -lh",
      "chmod 777 ./script.sh",
      "./script.sh",
      
    ]
  }

  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.strapi_pip.ip_address} >> local.txt"
  }

  connection {
    type        = "ssh"
    user        = "linuxusr"
    host        = azurerm_public_ip.strapi_pip.ip_address
    private_key = file(local_file.linuxkey.filename)
  }

  depends_on = [
    azurerm_network_interface.stra
pi_interface,
    tls_private_key.linux_key,
  ]
}
```
- This declares a resource block for an Azure Linux Virtual Machine with the name "linux_vm."
- These parameters set the basic configuration for the VM, including its name, the resource group it belongs to, its location, and the virtual machine size.
- This sets up the admin username and SSH key for accessing the VM.
- Associates the VM with a network interface.
- Configures the OS disk settings, including caching and storage account type.
- Specifies the source image for the VM, in this case, an Ubuntu Server image.
- Transfers a local script (script.sh) to the VM.
- Executes commands on the VM remotely, including listing files, changing script permissions, and running the script.
- Executes a local command after the VM is provisioned, appending the VM's public IP address to a local file (local.txt).
- Configures the SSH connection to the VM using the specified private key.

