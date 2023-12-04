# Define an EKS module for creating an Amazon EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.10.1"

  # Provide the security group ID for the EKS node group
  node_security_group_id = var.eks_node_group_sg_id

  # Define the name of the EKS cluster
  cluster_name = "${var.cluster_name}_${var.env}"

  # Specify the Kubernetes version for the EKS cluster
  cluster_version = var.cluster_version

  # Enable private and public access to the EKS cluster's API server
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Specify the VPC ID for the EKS cluster
  vpc_id = var.cluster_vpc

  # Provide the subnet IDs for the EKS cluster
  subnet_ids = var.subnet_ids

  # Enable IAM Roles for Service Accounts (IRSA)
  enable_irsa = true

  # Configure EKS managed node groups
  eks_managed_node_group_defaults = {
    use_custom_launch_template = true
    enable_bootstrap_user_data = true
    ami_id                     = var.ami_id != "" ? var.ami_id : null
  }
  eks_managed_node_groups = var.eks_managed_node_groups

  # Configure additional EKS cluster addons
  cluster_addons = var.cluster_addons

  # Specify tags for the EKS resources
  tags = var.tags

  # Manage AWS authentication ConfigMap for worker nodes
  manage_aws_auth_configmap = true

  # Specify AWS authentication roles for worker nodes
  aws_auth_roles = var.aws_auth_roles
}