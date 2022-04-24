provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "web_server_rg" {
  name                        = var.web_server_rg
  location                    = var.web_server_location
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                        = "${var.resource_prefix}-vnet"
  address_space               = [var.web_server_address_space]
  location                    = var.web_server_location
  resource_group_name         = azurerm_resource_group.web_server_rg.name
}

resource "azurerm_subnet" "web_server_subnet" {
  name                        = "${var.resource_prefix}-subnet"
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  virtual_network_name        = azurerm_virtual_network.web_server_vnet.name
  address_prefixes            = [var.web_server_address_prefix]
}

resource "azurerm_network_interface" "web_server_nic" {
  name                        = "${var.web_server_name}-nic"
  location                    = var.web_server_location
  resource_group_name         = azurerm_resource_group.web_server_rg.name

  ip_configuration {
    name                          = "${var.web_server_name}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_server_public_ip.id
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  name                        = "${var.resource_prefix}-public-ip"
  location                    = var.web_server_location
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  allocation_method           = var.environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                        = "${var.resource_prefix}-nsg"
  location                    = var.web_server_location
  resource_group_name         = azurerm_resource_group.web_server_rg.name
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
  protocol                    = "Tcp"
  source_port_range           = "3389"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  direction                   = "Inbound"
  priority                    = 100
  access                      = "Allow"
}

resource "azurerm_network_interface_security_group_association" "web_server_nsg_association" {
  network_interface_id        = azurerm_network_interface.web_server_nic.id
  network_security_group_id   = azurerm_network_security_group.web_server_nsg.id
}

resource "azurerm_windows_virtual_machine" "web_server" {
  name                          = var.web_server_name
  location                      = var.web_server_location
  resource_group_name           = azurerm_resource_group.web_server_rg.name
  network_interface_ids         = [azurerm_network_interface.web_server_nic.id]
  size                          = "Standard_B2S"
  admin_username                = "azureuser"
  admin_password                = "Passw0rd1234!"
  
  os_disk {
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1709-smalldisk"
    version   = "latest"
  }
}
