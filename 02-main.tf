##################################################
########## S3 Buckets And CloudFront  ############
##################################################

# Module for creating S3 buckets and associated CloudFront distributions
module "s3_and_cloudfront" {
  source       = "./modules/S3_CloudFront"
  project_name = var.project_name
  tags         = var.tags
  rules        = var.rules

  s3_bucket = [
    {
      name = "dev-privatevhub"
      default_cache_behavior = {
        cache_policy_id = module.cloudfront_policies.id[0]
        function_associations = [
          {
            function_arn = module.cloudfront_functions.function_arns[0]
            event_type   = module.cloudfront_functions.function_event_types[0]
          }
          # Add other function associations if needed
        ]
      }
      # Uncomment the Below Section if you've Certificate imported in AWS ACM 
      # viewer_certificate = {
      #   acm_certificate_arn      = "arn:aws:acm:us-east-1:**:certificate/***" # type String
      #   minimum_protocol_version = "TLSv1.2_2021"
      #   ssl_support_method       = "sni-only"
      #   aliases                  = ["auth.my-domain.xyz"] # type list(String)
      # }
    },
    # Add other S3 buckets if needed
  ]

  providers = {
    aws.failover_region = aws.failover_region
  }
}

##################################################
############ CloudFront Functions ################
##################################################

# Module for creating CloudFront functions
module "cloudfront_functions" {
  source               = "./modules/CloudFront_Function"
  cloudfront_functions = var.cloudfront_functions
}

##################################################
############ CloudFront Policies #################
##################################################

# Module for creating CloudFront cache policies
module "cloudfront_policies" {
  source              = "./modules/CloudFront_Policy"
  cloudfront_policies = var.cloudfront_policies
}

##################################################
################### Route_53  ####################
##################################################

# Module for configuring Route 53
module "route_53" {
  source    = "./modules/Route_53"
  zone_name = "my-domain.xyz"
  alias_records = {
    "my-domain.xyz" = {
      type         = "A"
      record_value = module.s3_and_cloudfront.s3_distribution[0]
    }
  }
}

##########################################
############### Network ##################
##########################################

# Module for creating VPC, subnets, and network components
module "network" {
  source                  = "./modules/Network"
  cidr_vpc                = var.cidr_vpc
  env                     = var.env
  tag_subnets_k8s_private = var.tag_subnets_k8s_private
  tag_subnets_k8s_public  = var.tag_subnets_k8s_public
  project_name            = var.project_name
  tags                    = var.tags
}

###########################################
################# EKS #####################
###########################################

# Module for creating Amazon EKS cluster
module "cluster_eks" {
  source                  = "./modules/EKS"
  cluster_name            = var.cluster_name
  cluster_version         = var.cluster_version
  project_name            = var.project_name
  env                     = var.env
  cluster_vpc             = module.network.vpc_id
  subnet_ids              = module.network.private_subnets
  eks_node_group_sg_id    = module.network.eks_node_group_sg_id
  eks_managed_node_groups = var.eks_managed_node_groups
  aws_auth_roles          = var.aws_auth_roles
  tags                    = var.tags
  cluster_addons = {
    vpc-cni = {
      addon_version     = "v1.15.3-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }
}

##########################################################
################## EKS Configuration #####################
##########################################################

# Module for configuring Amazon EKS after cluster creation
module "eks_config" {
  source                  = "./modules/EKS_Config"
  project_name            = var.project_name
  env                     = var.env
  tags                    = var.tags
  oidc_provider_arn       = module.cluster_eks.oidc_provider_arn
  cluster_name            = module.cluster_eks.cluster_name
  eks_managed_node_groups = module.cluster_eks.eks_managed_node_groups
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
}
