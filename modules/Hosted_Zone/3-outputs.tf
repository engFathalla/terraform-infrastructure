# Output: Zone IDs
# This output exports the Zone IDs of the created Route 53 hosted zones.
# It can be used to reference these Zone IDs in other parts of the Terraform configuration or outputs.

output "zone_id" {
  value = aws_route53_zone.zones.*.zone_id
}
