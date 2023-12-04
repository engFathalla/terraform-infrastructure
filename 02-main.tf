##################################################
########## S3 Buckets And CloudFront  ############
##################################################
module "s3_and_cloudfront" {
  source          = "./modules/s3_cf"
  s3_bucket_names = ["my-project-demo"]
  project_name    = var.project_name
  rules           = var.rules
  tags            = var.tags
  enable_cf       = true
  providers = {
    aws.region2 = aws.region2
  }
}
##################################################
################### Route_53  ####################
##################################################
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
module "cluster_eks" {
  source               = "./modules/EKS"
  cluster_name         = var.cluster_name
  cluster_version      = var.cluster_version
  project_name         = var.project_name
  env                  = var.env
  cluster_vpc          = module.network.vpc_id
  subnet_ids    = module.network.private_subnets
  eks_node_group_sg_id = module.network.eks_node_group_sg_id
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