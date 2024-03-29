provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  region = "eu-central-1"
  alias  = "failover_region"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.28.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.6.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }

    # Helm provider for managing Helm charts
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
  }
}

# Define the Kubernetes provider to manage resources on the EKS cluster
provider "kubernetes" {
  # The address of the EKS cluster
  host = module.cluster_eks.cluster_endpoint
  # Cluster CA certificate for authenticating to the cluster
  cluster_ca_certificate = base64decode(module.cluster_eks.cluster_certificate_authority_data)

  # Configuration for authenticating using AWS CLI
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.cluster_eks.cluster_name]
  }
}

# Define the kubectl provider to interact with the EKS cluster using kubectl
provider "kubectl" {
  # The address of the EKS cluster
  host = module.cluster_eks.cluster_endpoint
  # Cluster CA certificate for authenticating to the cluster
  cluster_ca_certificate = base64decode(module.cluster_eks.cluster_certificate_authority_data)
  # Do not load kubeconfig file for kubectl provider
  load_config_file = false

  # Configuration for authenticating using AWS CLI
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.cluster_eks.cluster_name]
    command     = "aws"
  }
}

# Define the Helm provider to manage Helm charts on the EKS cluster
provider "helm" {
  # Configuration for interacting with the EKS cluster
  kubernetes {
    host                   = module.cluster_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster_eks.cluster_certificate_authority_data)

    # Configuration for authenticating using AWS CLI
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.cluster_eks.cluster_name]
      command     = "aws"
    }
  }
}

