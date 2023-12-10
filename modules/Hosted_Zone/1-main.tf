# Create Route 53 Hosted Zones
# This resource block creates Route 53 hosted zones based on the specified names in the variable "hosted_zones".
# The count parameter is used to dynamically create multiple hosted zones based on the length of the "hosted_zones" list.

resource "aws_route53_zone" "zones" {
  count = length(var.hosted_zones)

  # Name of the hosted zone
  name = var.hosted_zones[count.index]

  # Tags to apply to the hosted zone
  tags = var.tags
}
