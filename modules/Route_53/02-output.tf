# Output the created alias records
output "alias-records" {
  value = aws_route53_record.alias-records
}

# Output the created non-alias records
output "non-alias-records" {
  value = aws_route53_record.non-alias-records
}