variable "cidr_vpc" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "project_name" {
  type        = string
  description = "Name of the project for resource naming."
}

variable "env" {
  type        = string
  description = "Environment identifier used in resource names."
}

variable "tags" {
  type        = map(any)
  description = "Map of Default Tags."
}

variable "tag_subnets_k8s_public" {
  type        = map(any)
  description = "Map of tags for Kubernetes public subnets."
  default     = {}
}

variable "tag_subnets_k8s_private" {
  type        = map(any)
  description = "Map of tags for Kubernetes private subnets."
  default     = {}
}
