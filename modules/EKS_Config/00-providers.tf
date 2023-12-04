# # Define required Terraform providers and their versions
terraform {
  required_providers {
    # kubectl provider for interacting with Kubernetes clusters
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