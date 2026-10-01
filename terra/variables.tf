variable "cidr_block" {
  default     = "10.0.0.0/16"
  type        = string
  description = "Base VPC CIDR"
}

variable "cluster_name" {
  default     = "eks-cluster-terra"
  type        = string
  description = "Name of the EKS Cluster"
}

variable "node_group_name" {
  default     = "node-group-terra"
  type        = string
  description = "Name of the EKS Cluster Worker Node"
}

variable "node_group_instance_types" {
  default     = ["c7i-flex.large"] # Must be a list, not a string
  type        = list(string)
  description = "Instance Type of the Worker Node"
}


