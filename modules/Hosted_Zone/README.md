# Terraform AWS Cloudfront function 🔥

This Terraform module provisions Hosted Zone resources.

## Table of Contents

- [Introduction](#introduction)
- [Usage](#usage)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Introduction

The `aws_route53_zone` module is designed to manage Route 53 Hosted Zones on AWS. Amazon Route 53 is a scalable and highly available Domain Name System (DNS) web service that converts user-friendly domain names, such as www.example.com, into IP addresses.

### Features

- **Scalable DNS Management**: Easily create, update, and delete DNS records for your domains.
- **High Availability**: Route 53 provides a reliable and cost-effective way to route end users to Internet applications.
- **Custom Domain Names**: Manage custom domain names for your applications, services, and resources.

### Module Overview

This module allows you to create multiple hosted zones based on the specified domain names. It provides flexibility in managing different domains within your AWS infrastructure.
## Usage

```hcl
module "route53_zones" {
  source         = "./modules/route53_zones"
  hosted_zones   = ["example.com", "subdomain.example.com"]
  tags = {
    Environment = "Production"
    Project     = "MyProject"
  }
}

output "zone_ids" {
  value = module.route53_zones.zone_id
}
```

## Inputs
| Variable         | Type           | Required/Optional | Description                                  |
| ---------------- | -------------- | ------------------ | -------------------------------------------- |
| `tags`           | `map(any)`     | **Required**       | Map of Default Tags.                         |
| `hosted_zones`   | `list(string)` | **Optional**       | List of hosted zones for AWS Route 53. Default is an empty list. |

## Outputs
| Output         | Description                                      |
| -------------- | ------------------------------------------------ |
| `zone_id`      | List of Zone IDs created for the hosted zones.   |
