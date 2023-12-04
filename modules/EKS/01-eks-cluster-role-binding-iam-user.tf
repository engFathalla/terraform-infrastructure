# Define a Kubernetes ClusterRole granting full access to all resources
resource "kubernetes_cluster_role" "eks-dev-user-full-access-clusterrole" {
  metadata {
    # Set the name for the ClusterRole
    name = "dc-admin-cluster-role"
  }

  # Define rules for the ClusterRole, allowing all actions on all resources in all API groups
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  # Depend on the EKS module to ensure the EKS cluster is created before creating the ClusterRole
  depends_on = [
    module.eks
  ]
}

# Define a Kubernetes ClusterRoleBinding associating a group with the previously defined ClusterRole
resource "kubernetes_cluster_role_binding" "eks-dev-user-full-access-binding" {
  metadata {
    # Set the name for the ClusterRoleBinding
    name = "dc-admin-cluster-rolebinding"
  }

  # Define the subject of the ClusterRoleBinding, specifying the group, kind, and API group
  subject {
    kind      = "Group"
    name      = "dc:cluster:admin"
    api_group = "rbac.authorization.k8s.io"
  }

  # Define the reference to the ClusterRole, specifying the kind and name
  role_ref {
    kind      = "ClusterRole"
    name      = "dc-admin-cluster-role"
    api_group = "rbac.authorization.k8s.io"
  }

  # Depend on the EKS module to ensure the EKS cluster is created before creating the ClusterRoleBinding
  depends_on = [
    module.eks
  ]
}
