# Project Configuration
variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "elastic-lab"
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-elastic-lab"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Lab"
    Project     = "Elasticsearch-SIEM"
    ManagedBy   = "Terraform"
  }
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Security Configuration
variable "allowed_ssh_source" {
  description = "Source IP address or CIDR allowed for SSH (use your public IP or * for any)"
  type        = string
  default     = "*"
}

variable "allowed_rdp_source" {
  description = "Source IP address or CIDR allowed for RDP (use your public IP or * for any)"
  type        = string
  default     = "*"
}

variable "allowed_kibana_source" {
  description = "Source IP address or CIDR allowed for Kibana access (use your public IP or * for any)"
  type        = string
  default     = "*"
}

# Linux VM Configuration
variable "linux_vm_count" {
  description = "Number of Linux VMs to create (0-2 recommended)"
  type        = number
  default     = 1
  validation {
    condition     = var.linux_vm_count >= 0 && var.linux_vm_count <= 5
    error_message = "Linux VM count must be between 0 and 5"
  }
}

variable "linux_vm_size" {
  description = "Size of the Linux VM (e.g., Standard_D2s_v3 = 2 vCPU, 8GB RAM)"
  type        = string
  default     = "Standard_D2s_v3"
  # Common sizes:
  # Standard_B2s     - 2 vCPU, 4GB RAM  (Burstable, cheapest)
  # Standard_D2s_v3  - 2 vCPU, 8GB RAM  (Recommended for Elastic)
  # Standard_D4s_v3  - 4 vCPU, 16GB RAM (Multi-node Elastic)
  # Standard_E2s_v3  - 2 vCPU, 16GB RAM (Memory-optimized)
}

variable "linux_admin_username" {
  description = "Admin username for Linux VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "linux_os_disk_type" {
  description = "OS disk type for Linux VMs (Standard_LRS, StandardSSD_LRS, Premium_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "linux_os_disk_size" {
  description = "OS disk size in GB for Linux VMs"
  type        = number
  default     = 64
}

# Windows VM Configuration
variable "windows_vm_count" {
  description = "Number of Windows VMs to create (0 or 1 recommended)"
  type        = number
  default     = 0
  validation {
    condition     = var.windows_vm_count >= 0 && var.windows_vm_count <= 2
    error_message = "Windows VM count must be between 0 and 2"
  }
}

variable "windows_vm_size" {
  description = "Size of the Windows VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "windows_admin_username" {
  description = "Admin username for Windows VMs"
  type        = string
  default     = "azureadmin"
}

variable "windows_admin_password" {
  description = "Admin password for Windows VMs (minimum 12 characters)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "windows_os_disk_type" {
  description = "OS disk type for Windows VMs"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "windows_os_disk_size" {
  description = "OS disk size in GB for Windows VMs"
  type        = number
  default     = 128
}
