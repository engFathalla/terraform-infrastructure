# Default Tags
# This variable defines a map of default tags that can be applied to various AWS resources.
# These tags are used to provide metadata and organization to resources.

variable "tags" {
  type        = map(any)
  description = "Map of Default Tags"
}

# Hosted Zones
# This variable defines a list of domain names for which Route 53 hosted zones will be created.
# The default value is an empty list, and you can customize it by providing specific domain names.

variable "hosted_zones" {
  type    = list(string)
  default = []
}
