# Terraform Infrastructure as Code (IaC) Project 🚀

This project leverages Terraform to define and provision cloud infrastructure components on AWS. The project is organized into modules, each responsible for specific aspects of the infrastructure.


## Table of Contents

- [General Configuration](#general-configuration)
- [S3 Buckets and CloudFront](#s3-buckets-and-cloudfront)
- [CloudFront Functions](#cloudfront-functions)
- [CloudFront Policies](#cloudfront-policies)
- [Hosted Zone](#hosted-zone)
- [Route 53](#route-53)
- [Network](#network)
- [Amazon EKS](#amazon-eks)
- [EKS Configuration](#eks-configuration)

## General Configuration

### Variables

- **project_name**: Name of the project for resource naming.
- **env**: Environment identifier used in resource names.
- **tags**: Map of default tags.
- **region**: AWS region.

#### Example `terraform.tfvars`:

```hcl
project_name = "demo-project"
env          = "prod"
region       = "eu-west-1"
tags = {
  Project     = "demo-project"
  Environment = "PROD"
}
```

## S3 Buckets and CloudFront

### Variables

- **rules**: Map of rules for S3 bucket lifecycle configuration.

#### Example `terraform.tfvars`:

```hcl
rules = {
  "keep-latest-version" = {
    status = "Enabled"
    noncurrent_version_expiration = {
      newer_noncurrent_versions = 13
      noncurrent_days           = 31
    }
    noncurrent_version_transition = {
      newer_noncurrent_versions = 1
      noncurrent_days           = 30
      storage_class             = "STANDARD_IA"
    }
    abort_incomplete_multipart_upload = {
      days_after_initiation = 1
    }
  }
}

```

## CloudFront Functions

### Variables

- **cloudfront_functions**:  List of CloudFront functions.

#### Example `terraform.tfvars`:

```hcl
cloudfront_functions = [
  {
    name       = "url-rewrite"
    runtime    = "cloudfront-js-1.0"
    comment    = "url-rewrite"
    publish    = true
    code       = "CloudFront_Functions/url-rewrite.js"
    event_type = "viewer-request"
  }
]
```

## CloudFront Policies

### Variables

- **cloudfront_policies**:  List of CloudFront cache policies.

#### Example `terraform.tfvars`:

```hcl
cloudfront_policies = [
  {
    name                          = "cache_policy"
    comment                       = "cache_policy"
    default_ttl                   = 30672000
    min_ttl                       = 0
    max_ttl                       = 30672000
    supported_compression_formats = ["BROTLI", "GZIP"]
    cache_keys_in_cookies = { behavior = "ALL" }
    cache_keys_in_headers = { behavior = "WHITELIST", items = ["cloudfront-viewer-country"] }
    cache_keys_in_query_strings = { behavior = "ALL" }
  }
]
```
## Hosted Zone

### Variables

- **hosted_zones**: List of hosted zones to configure.

#### Example `terraform.tfvars`:

```hcl
hosted_zones = ["my-domain.xyz"]
```
## Route 53

### Variables

- **zone_name**: The name of the hosted zone.
- **alias_records**: Map of alias records to configure.

#### Example `terraform.tfvars`:

```hcl
zone_name = "my-domain.xyz"
alias_records = {
  "my-domain.xyz" = {
    type         = "A"
    record_value = module.s3_and_cloudfront.s3_distribution[0]
  }
}

## Network

### Variables

- **cidr_vpc**: VPC CIDR block.
- **tag_subnets_k8s_private**:  Tags for Kubernetes private subnets.
- **tag_subnets_k8s_public**:  Tags for Kubernetes public subnets.

#### Example `terraform.tfvars`:

```hcl
cidr_vpc = "10.32.0.0/16"
tag_subnets_k8s_private = {
  Project                           = "demo-project"
  Environment                       = "PROD"
  "kubernetes.io/role/internal-elb" = "1"
}
tag_subnets_k8s_public = {
  Project                  = "demo-project"
  Environment              = "PROD"
  "kubernetes.io/role/elb" = "1"
}
```

## Amazon EKS

### Variables

- **cluster_name**: Amazon EKS cluster name.
- **cluster_version**:  Amazon EKS cluster version.
- **eks_managed_node_groups**:  Map of configurations for managed node groups.
- **aws_auth_roles**:  List of AWS authentication roles for EKS.

#### Example `terraform.tfvars`:

```hcl
cluster_name = "demo-project"
cluster_version = "1.27"
eks_managed_node_groups = {
  "demo-project" = {
    desired_size               = 1
    min_size                   = 1
    max_size                   = 10
    use_custom_launch_template = true
    enable_bootstrap_user_data = true
    labels = { role = "demo-project" }
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 60
          volume_type           = "gp2"
          iops                  = 0
          encrypted             = true
          delete_on_termination = true
        }
      }
    }
    taints = {}
    tags = { Project = "demo-project", Environment = "PROD" }
  }
}
aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::<Account-ID>:role/Administrator"
    username = "eks-web-console"
    groups   = ["dc:cluster:admin"]
  }
]
```
## EKS Configuration

### Variables

- **oidc_provider_arn**: OIDC provider ARN for EKS.
- **namespaces_config**:   Map of configurations for Kubernetes namespaces.
- **alb_config**:  Configurations for Application Load Balancer (ALB).
- **autoscaler_config**:  Configurations for cluster autoscaler.
- **external_dns_config**:  Configurations for external DNS.
- **kyverno_config**: Configurations for Kyverno.

#### Example `terraform.tfvars`:

```hcl
oidc_provider_arn       = "arn:aws:eks:region:account-id:cluster/cluster-name/id/oidc-provider/id"
namespaces_config = {
  "prod" = {
    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}
alb_config = {
  enable           = true
  helmChartVersion = "1.6.2"
}
autoscaler_config = {
  enable       = true
  imageVersion = "1.26.1"
}
external_dns_config = {
  enable           = true
  helmChartVersion = "6.28.5"
  helm_values_file = "./external-dns-helm-values.yaml"
}
kyverno_config = {
  enable           = false
  helmChartVersion = "3.1.0"
}
```