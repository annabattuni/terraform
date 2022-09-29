terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.22.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {

  }
}
module "create-rg-01" {
  source = "./modules/rg"
  rg_name = var.rg_01_name
  rg_location = var.rg_01_location
  tag_env_name = var.tag_env_name
}

resource "azurerm_virtual_network" "vnet-01" {
  name                = var.vnet_01_name
  address_space       = var.vnet_01_address_space
  location            = var.rg_01_location
  resource_group_name = var.rg_01_name
  depends_on = [
    module.create-rg-01
  ]
}

resource "azurerm_subnet" "subnet-01" {
  name                 = var.subnet_01_name
  resource_group_name  = var.rg_01_name
  virtual_network_name = var.vnet_01_name
  address_prefixes     = var.subnet_01_address_perfix
depends_on = [
    module.create-rg-01
  ]
}

resource "azurerm_network_security_group" "nsg-01" {
  name                = var.nsg_01_name
  location            = var.rg_01_location
  resource_group_name = var.rg_01_name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
depends_on = [
    module.create-rg-01
  ]
}


resource "azurerm_subnet_network_security_group_association" "nsg-ass-01" {
  subnet_id                 = azurerm_subnet.subnet-01.id
  network_security_group_id = azurerm_network_security_group.nsg-01.id
}



resource "azurerm_network_interface" "nic-01" {
  name                = var.nic_01_name
  location            = var.rg_01_location
  resource_group_name = var.rg_01_name
  ip_configuration {
    name                          = "config01"
    private_ip_address = var.private_ip_address
    subnet_id = azurerm_subnet.subnet-01.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm-01" {
  name                = var.vm_01_name
  resource_group_name = var.rg_01_name
  location            = var.rg_01_location
  size                = "Standard_B1s"
  admin_username      = "localuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [azurerm_network_interface.nic-01.id]
   depends_on = [
    module.create-rg-01
  ]
    os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
resource "azurerm_public_ip" "pip-01" {
  name                = var.pip_01_name
  resource_group_name = var.rg_01_name
  location            = var.rg_01_location
  public_ip_address_prefix = var.public_ip_address_prefix
  allocation_method   = "Static"
depends_on = [
    module.create-rg-01
  ]
  tags = {
    environment = var.tag_env_name
  }
}
  
