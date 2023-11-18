# Automate installation of Strapi 
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
```
- Azure Storage Account named "pstroage" in the specified Azure Resource Group (nstrapi_rg).
- It's set to use the "Standard" storage tier with Locally Redundant Storage (LRS) replication for redundancy.
- Azure Storage Container named "secretfile" within the previously defined Storage Account. The access type is set to "private," meaning only authorized users can access the container.

backend.tf
```
terraform {
  backend "azurerm" {
    resource_group_name = "nstrapi-rg"
    storage_account_name = "strapistroage"
    container_name = "secretfile"
    key = "terraform.tfstate"
  }
}
```
- backend: This specifies the type of backend to use for storing Terraform state. In this case, it's set to "azurerm," indicating the Azure Resource Manager backend.

- resource_group_name: Specifies the name of the Azure Resource Group where the storage account is located or where it should be created. In this case, it's set to "nstrapi-rg."

- storage_account_name: Specifies the name of the Azure Storage Account where the Terraform state file will be stored. In this case, it's set to "strapistroage."

- container_name: Specifies the name of the container within the specified Azure Storage Account. In this case, the container is named "secretfile."

- key: Specifies the name of the Terraform state file within the specified container. The state file is named "terraform.tfstate."



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

## strapi script.sh
```
#!/bin/bash

show_message() {
  echo "-------------------------------------------------------------"
  echo "$1"
  echo "-------------------------------------------------------------"
}

show_message "Update system packages"
sudo apt update

show_message "Install Node.js and npm"
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y

show_message "Update system again"
sudo apt update

show_message "Install PostgreSQL"
sudo apt install postgresql postgresql-contrib -y
sudo systemctl start postgresql.service

show_message "Install Nginx"
sudo apt install nginx -y
sudo ufw allow 'Nginx HTTP'
sudo systemctl start nginx

show_message "Update Nginx site configuration"

url=$(curl -s ifconfig.me)

sudo tee /etc/nginx/sites-available/$url <<EOL
server {
    listen 80;
    listen [::]:80;

    server_name $url www.$url;

    location / {
        proxy_pass http://localhost:1337;
        include proxy_params;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/$url /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

show_message "Configure PostgreSQL"

sudo -i  -u postgres createdb strapi
sudo -i -u postgres createuser nikhil
sudo -i -u postgres psql -c "ALTER USER nikhil PASSWORD 'admin';"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE strapi TO nikhil;"

show_message "Create Strapi app"

yes | npx create-strapi-app@latest my-project \
  --dbclient=postgres \
  --dbhost=127.0.0.1 \
  --dbname=strapi \
  --dbusername=nikhil \
  --dbpassword=admin \
  --dbport=5432

cd my-project
NODE_ENV=production npm run build
nohup node /home/linuxusr/my-project/node_modules/.bin/strapi start > /dev/null 2>&1 &
show_message "Strapi app has been started"

```
- updates the package lists for upgrades and new package installations.
- install Node.js and npm. The first line uses curl to download and execute a script from NodeSource that adds the Node.js 18.x repository, and the second line installs Node.js.
- install PostgreSQL and start its service.
- install Nginx, allow HTTP traffic through the firewall, and start the Nginx service.
- Retrieves the public IP address using curl ifconfig.me.
- Creates an Nginx server block configuration file for the obtained IP address. Links the configuration file to the sites-enabled directory.
- Tests the Nginx configuration and restarts Nginx.
- Creates a PostgreSQL database named "strapi."
- Creates a PostgreSQL user named "nikhil" with the password "admin."
- Grants all privileges on the "strapi" database to the "nikhil" user.
- Uses npx create-strapi-app to generate a new Strapi project called "my-project."
- Configures the Strapi app to use PostgreSQL with the specified credentials.
- Changes into the "my-project" directory.
- Builds the Strapi app for production using npm run build.
- Starts the Strapi app in the background using nohup and redirects output to /dev/null.

![image](https://github.com/nikhilk1699/strapi_installation/assets/109533285/8d5b38a4-eee1-4500-9fc2-d9761afcfbcc)
![Screenshot 2023-11-17 192404](https://github.com/nikhilk1699/strapi_installation/assets/109533285/36f4c2f5-dc9d-4b0c-882f-470dbed9d2dc)
![Screenshot 2023-11-17 192404](https://github.com/nikhilk1699/strapi_installation/assets/109533285/4c81d86d-fb4a-4f98-9878-2b41f0e368fe)
![Screenshot 2023-11-17 192505](https://github.com/nikhilk1699/strapi_installation/assets/109533285/30f11027-4762-42cd-815b-bace138f628c)
![Screenshot 2023-11-17 192726](https://github.com/nikhilk1699/strapi_installation/assets/109533285/b269f4e4-dc22-41da-b4fb-aa0ef20d84d4)






