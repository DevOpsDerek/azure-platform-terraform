output "resource_group_name" {
  description = "Name of the platform resource group."
  value       = azurerm_resource_group.platform.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.platform.name
}

output "aks_node_resource_group" {
  description = "AKS-managed node resource group."
  value       = azurerm_kubernetes_cluster.platform.node_resource_group
}
