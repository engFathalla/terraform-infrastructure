# The name of the EKS cluster
variable "cluster_name" {
  type        = string
  description = "The name of the Amazon EKS cluster"
}

# The version of the EKS cluster
variable "cluster_version" {
  type        = string
  description = "The desired Kubernetes version for the Amazon EKS cluster"
}

# The ID of the VPC in which to create the EKS cluster
variable "cluster_vpc" {
  type        = string
  description = "The ID of the VPC in which to create the Amazon EKS cluster"
}

# The name of the project
variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

# The ID of a custom Amazon Machine Image (AMI) to use for the worker nodes
variable "ami_id" {
  type        = string
  default     = ""
  description = "The ID of a custom Amazon Machine Image (AMI) to use for the worker nodes"
}

# Map of node group configurations
variable "eks_managed_node_groups" {
  description = "Map of node group configurations"
  type        = map(any)
}

# List of AWS auth roles
variable "aws_auth_roles" {
  description = "List of AWS auth roles"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

# The ID of the first private subnet
variable "subnet_ids" {
  type = list(string)
}


# The environment (e.g., dev, stage, prod)
variable "env" {
  type        = string
  description = "The environment (e.g., dev, stage, prod)"
}

# Tags to apply to all resources created by this module
variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources created by this module"
}

# The ID of the security group for the EKS worker nodes
variable "eks_node_group_sg_id" {
  type        = string
  description = "The ID of the security group for the Amazon EKS worker nodes"
}

# Addons to deploy in the Amazon EKS cluster
variable "cluster_addons" {
  type = any
  default = {
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    vpc-cni            = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }
  description = "Addons to deploy in the Amazon EKS cluster"
}
