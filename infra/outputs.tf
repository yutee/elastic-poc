# Output Configuration

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.lab.name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.lab.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.lab.id
}

output "linux_vm_details" {
  description = "Details of Linux VMs"
  value = {
    for idx, vm in azurerm_linux_virtual_machine.linux : vm.name => {
      vm_name        = vm.name
      public_ip      = azurerm_public_ip.linux[idx].ip_address
      private_ip     = azurerm_network_interface.linux[idx].private_ip_address
      admin_username = vm.admin_username
      ssh_command    = "ssh ${vm.admin_username}@${azurerm_public_ip.linux[idx].ip_address}"
      vm_size        = vm.size
    }
  }
}

output "windows_vm_details" {
  description = "Details of Windows VMs"
  value = {
    for idx, vm in azurerm_windows_virtual_machine.windows : vm.name => {
      vm_name        = vm.name
      public_ip      = azurerm_public_ip.windows[idx].ip_address
      private_ip     = azurerm_network_interface.windows[idx].private_ip_address
      admin_username = vm.admin_username
      rdp_command    = "mstsc /v:${azurerm_public_ip.windows[idx].ip_address}"
      vm_size        = vm.size
    }
  }
  sensitive = false
}

output "network_summary" {
  description = "Network configuration summary"
  value = {
    vnet_address_space    = azurerm_virtual_network.lab.address_space[0]
    subnet_address_prefix = azurerm_subnet.lab.address_prefixes[0]
    total_linux_vms       = var.linux_vm_count
    total_windows_vms     = var.windows_vm_count
  }
}

output "elasticsearch_urls" {
  description = "Potential Elasticsearch and Kibana URLs (after installation)"
  value = {
    for idx, vm in azurerm_linux_virtual_machine.linux : vm.name => {
      elasticsearch = "http://${azurerm_public_ip.linux[idx].ip_address}:9200"
      kibana        = "http://${azurerm_public_ip.linux[idx].ip_address}:5601"
    }
  }
}

output "quick_connect_guide" {
  description = "Quick connection commands"
  value       = <<-EOT
    
    Linux VMs SSH Access:
    ${join("\n    ", [for idx, vm in azurerm_linux_virtual_machine.linux : "ssh ${vm.admin_username}@${azurerm_public_ip.linux[idx].ip_address}"])}
    
    Windows VMs RDP Access:
    ${join("\n    ", [for idx, vm in azurerm_windows_virtual_machine.windows : "mstsc /v:${azurerm_public_ip.windows[idx].ip_address}"])}
    
    After Elasticsearch installation, access Kibana at:
    ${join("\n    ", [for idx, vm in azurerm_linux_virtual_machine.linux : "http://${azurerm_public_ip.linux[idx].ip_address}:5601"])}
    
  EOT
}
