# Retrieve information about the Route 53 zone based on the provided zone_name
data "aws_route53_zone" "zone" {
  name         = var.zone_name
  private_zone = false
}

# Create Route 53 records with aliases
resource "aws_route53_record" "alias-records" {
  for_each        = var.alias_records
  allow_overwrite = true
  zone_id         = data.aws_route53_zone.zone.zone_id
  name            = each.key
  type            = each.value.type
  ttl             = null
  health_check_id = lookup(each.value, "health_check_id", null)
  set_identifier  = lookup(each.value, "set_identifier", null)
  dynamic "failover_routing_policy" {
    for_each = lookup(each.value, "failover_routing_policy", [])
    content {
      type = failover_routing_policy.value
    }
  }

  # Create dynamic alias block if there are alias records
  dynamic "alias" {
    for_each = length(each.value.record_value) > 0 ? [1] : []
    content {
      name                   = each.value.record_value.domain_name
      zone_id                = each.value.record_value.hosted_zone_id
      evaluate_target_health = lookup(each.value, "evaluate_target_health", false)
    }
  }
}

# Create Route 53 records without aliases
resource "aws_route53_record" "non-alias-records" {
  for_each        = var.non_alias_records
  allow_overwrite = true
  zone_id         = data.aws_route53_zone.zone.zone_id
  name            = each.key
  type            = each.value.type
  ttl             = each.value.ttl
  records         = each.value.record_value
  health_check_id = lookup(each.value, "health_check_id", null)
  set_identifier  = lookup(each.value, "set_identifier", null)
  dynamic "failover_routing_policy" {
    for_each = lookup(each.value, "failover_routing_policy", [])
    content {
      type = failover_routing_policy.value
    }
  }
}