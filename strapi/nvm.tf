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
    azurerm_network_interface.strapi_interface,
    tls_private_key.linux_key,
  ]
}
