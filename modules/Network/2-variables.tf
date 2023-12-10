# Variable for defining CIDR block for the VPC.
variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC."
}

# Variable for defining the project name used for resource naming.
variable "project_name" {
  type        = string
  description = "Name of the project for resource naming."
}

# Variable for defining the environment identifier used in resource names.
variable "env" {
  type        = string
  description = "Environment identifier used in resource names."
}

# Variable for defining a map of Default Tags.
variable "tags" {
  type        = map(any)
  description = "Map of Default Tags."
}

# Variable for defining a map of tags for Kubernetes public subnets.
variable "tag_subnets_k8s_public" {
  type        = map(any)
  description = "Map of tags for Kubernetes public subnets."
  default     = {}
}

# Variable for defining a map of tags for Kubernetes private subnets.
variable "tag_subnets_k8s_private" {
  type        = map(any)
  description = "Map of tags for Kubernetes private subnets."
  default     = {}
}
