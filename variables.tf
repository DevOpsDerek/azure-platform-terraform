variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
  default     = "ref"
}

variable "environment" {
  description = "Environment identifier (for example: dev, test, prod)."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all deployed resources."
  type        = string
  default     = "eastus"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.30.9"
}

variable "node_count" {
  description = "Number of system nodes for the default node pool."
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM SKU for the AKS default node pool."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "address_space" {
  description = "Address space for the platform VNet."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "aks_subnet_cidr" {
  description = "Subnet CIDR for AKS nodes."
  type        = string
  default     = "10.10.0.0/24"
}

variable "authorized_ip_ranges" {
  description = "Allowed CIDR ranges for AKS API server access."
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
