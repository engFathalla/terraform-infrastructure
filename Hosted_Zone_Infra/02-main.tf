resource "aws_route53_zone" "zones" {
  count = length(var.hosted_zones)
  name = var.hosted_zones[count.index]
  tags = var.tags
}


