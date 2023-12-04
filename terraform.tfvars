##########################################
############### General ##################
##########################################
project_name= "demo-project"
env = "prod"
region = "eu-west-1"
tags = {
      Project         = "demo-project"
      Environment     = "PROD"
}

##################################################
########## S3 Buckets And CloudFront  ############
##################################################
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

##########################################
############### Network ##################
##########################################
cidr_vpc="10.32.0.0/16"
tag_subnets_k8s_private= {
      Project         = "demo-project"
      Environment     = "PROD"
    "kubernetes.io/role/internal-elb" = "1"
  }
tag_subnets_k8s_public={
      Project         = "demo-project"
      Environment     = "PROD"
    "kubernetes.io/role/elb" = "1"
  }

##########################################
################# EKS ####################
##########################################
cluster_name = "demo-project"
cluster_version = "1.27"
eks_managed_node_groups = {
  "demo-project" = {
    desired_size   = 1
    min_size       = 1
    max_size       = 10
    use_custom_launch_template = true
    enable_bootstrap_user_data = true
    labels = {
      role = "demo-project"
    }
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
    tags = {
      Project         = "demo-project"
      Environment     = "PROD"
    }
  }
}
aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::878202868047:role/Administrator"
    username = "eks-web-console"
    groups   = ["dc:cluster:admin"]
  },
  {
    rolearn  = "arn:aws:iam::878202868047:role/DevOps"
    username = "eks-web-console"
    groups   = ["dc:cluster:admin"]
  }
]
