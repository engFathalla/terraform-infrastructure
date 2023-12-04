# Define a variable for alias records, defaulting to an empty map
variable "alias_records" {
  type    = any
  default = {}
}

# Define a variable for the Route 53 zone name
variable "zone_name" {
  type = string
}

# Define a variable for non-alias records, defaulting to an empty map
variable "non_alias_records" {
  type    = any
  default = {}
}