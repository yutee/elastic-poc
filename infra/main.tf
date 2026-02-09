terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "lab" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "lab" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Network Security Group
resource "azurerm_network_security_group" "lab" {
  name                = "${var.project_name}-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  # SSH access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_source
    destination_address_prefix = "*"
  }

  # RDP access
  security_rule {
    name                       = "RDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_rdp_source
    destination_address_prefix = "*"
  }

  # Elasticsearch API
  security_rule {
    name                       = "Elasticsearch"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9200"
    source_address_prefix      = var.vnet_address_space
    destination_address_prefix = "*"
  }

  # Kibana
  security_rule {
    name                       = "Kibana"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5601"
    source_address_prefix      = var.allowed_kibana_source
    destination_address_prefix = "*"
  }

  # Logstash
  security_rule {
    name                       = "Logstash"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5044"
    source_address_prefix      = var.vnet_address_space
    destination_address_prefix = "*"
  }
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "lab" {
  subnet_id                 = azurerm_subnet.lab.id
  network_security_group_id = azurerm_network_security_group.lab.id
}

# Public IPs for Linux VMs
resource "azurerm_public_ip" "linux" {
  count               = var.linux_vm_count
  name                = "${var.project_name}-linux-${count.index + 1}-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interfaces for Linux VMs
resource "azurerm_network_interface" "linux" {
  count               = var.linux_vm_count
  name                = "${var.project_name}-linux-${count.index + 1}-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux[count.index].id
  }
}

# Linux Virtual Machines
resource "azurerm_linux_virtual_machine" "linux" {
  count               = var.linux_vm_count
  name                = "${var.project_name}-linux-${count.index + 1}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  size                = var.linux_vm_size
  admin_username      = var.linux_admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.linux[count.index].id,
  ]

  admin_ssh_key {
    username   = var.linux_admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.linux_os_disk_type
    disk_size_gb         = var.linux_os_disk_size
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "${var.project_name}-linux-${count.index + 1}"
  disable_password_authentication = true
}

# Public IP for Windows VM
resource "azurerm_public_ip" "windows" {
  count               = var.windows_vm_count
  name                = "${var.project_name}-windows-${count.index + 1}-pip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interface for Windows VM
resource "azurerm_network_interface" "windows" {
  count               = var.windows_vm_count
  name                = "${var.project_name}-windows-${count.index + 1}-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows[count.index].id
  }
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "windows" {
  count               = var.windows_vm_count
  name                = "${var.project_name}-win-${count.index + 1}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  size                = var.windows_vm_size
  admin_username      = var.windows_admin_username
  admin_password      = var.windows_admin_password
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.windows[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.windows_os_disk_type
    disk_size_gb         = var.windows_os_disk_size
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  computer_name = "${var.project_name}-win-${count.index + 1}"
}
