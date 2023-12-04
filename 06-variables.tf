##########################################
############### General ##################
##########################################
variable "project_name" {
  type = string
}
variable "env" {
  type = string
}
variable "tags" {
  type        = map(any)
  description = "Map of Default Tags"
}
variable "region" {
  type = string
}


##################################################
########## S3 Buckets And CloudFront  ############
##################################################
variable "rules" {
  type = map(object({
    status = string
    noncurrent_version_expiration = optional(object({
      newer_noncurrent_versions = number #Number of noncurrent versions Amazon S3 will retain. Must be a non-zero positive integer.
      noncurrent_days           = number #Number of days an object is noncurrent before Amazon S3 can perform the associated action. Must be a positive integer
    }))
    noncurrent_version_transition = optional(object({
      newer_noncurrent_versions = number # Number of noncurrent versions Amazon S3 will retain. Must be a non-zero positive integer
      noncurrent_days           = number # Number of days an object is noncurrent before Amazon S3 can perform the associated action.
      storage_class             = string # Class of storage used to store the object. Valid Values: GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR
    }))
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number #Number of days after which Amazon S3 aborts an incomplete multipart upload.
    }))
  }))
}


##########################################
############### Netwrok ##################
##########################################
variable "cidr_vpc" {
  type        = string
  description = "vpc cidr block"
}

variable "tag_subnets_k8s_private" {
  type        = map(any)
  description = "tag to private subnets"
}
variable "tag_subnets_k8s_public" {
  type        = map(any)
  description = "tags to public subnetes"
}

##########################################
################# EKS ####################
##########################################
variable "cluster_name" {
  type = string
}
variable "cluster_version" {
  type = string
}

variable "eks_managed_node_groups" {
  description = "Map of node group configurations"
  type        = map(any)
}
variable "aws_auth_roles" {
  description = "List of AWS auth roles"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

# ##########################################
# ################ Redis ###################
# ##########################################
# variable "replication_group_id_redis" {
#   type        = string
#   description = "replication group id for redis"
# }
# variable "port" {
#   type        = string
#   description = "Redis port"
# }
# variable "family" {
#   type        = string
#   description = "paramter group family"
# }
# variable "engine_version" {
#   type        = string
#   description = "engine version"
# }
# variable "replicas_per_node_group" {
#   type        = string
#   description = "Replicas per node group"
# }
# variable "num_node_groups" {
#   type        = string
#   description = "no of nodes to redis cluster"
# }
# variable "node_type" {
#   type        = string
#   description = "node types"
# }
# variable "snapshot_window" {
#   type = string
# }
# variable "snapshot_retention_limit" {
#   type = string
# }