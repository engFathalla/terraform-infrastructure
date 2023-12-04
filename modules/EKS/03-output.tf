# The ID of the security group for the EKS worker nodes
output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

# The ID of the security group for the entire EKS cluster
output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

# The status of the Amazon EKS cluster
output "eks_cluster_status" {
  value = module.eks.cluster_status
}

# The Amazon Resource Name (ARN) of the OIDC provider
output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

# The OIDC provider URL
output "oidc_provider" {
  value = module.eks.oidc_provider
}

# The URL of the issuer for the OIDC provider
output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

# The name of the Amazon EKS cluster
output "cluster_name" {
  value = module.eks.cluster_name
}

# The endpoint for your Kubernetes API server
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

# The certificate-authority-data for your cluster
output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

# Information about the Amazon EKS managed node groups
output "eks_managed_node_groups" {
  value = module.eks.eks_managed_node_groups
}
