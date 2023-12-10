# Create an IAM policy for the Application Load Balancer (ALB)
resource "aws_iam_policy" "alb" {
  # Conditional creation based on the enable flag in alb_config
  count  = var.alb_config["enable"] ? 1 : 0
  name   = "${var.project_name}_${var.env}-alb"
  policy = file("Policies/iam_policy.json")
}

# Attach the ALB IAM policy to specified IAM roles
resource "aws_iam_role_policy_attachment" "alb_general" {
  # Conditional creation based on the enable flag in alb_config
  for_each   = var.alb_config["enable"] ? var.eks_managed_node_groups : {}
  role       = split("/", var.eks_managed_node_groups[each.key]["iam_role_arn"])[1]
  policy_arn = aws_iam_policy.alb[0].arn
}

# Fetch ALB CRDs (Custom Resource Definitions) from GitHub
data "http" "alb_crds" {
  # Conditional creation based on the enable flag in alb_config
  count = var.alb_config["enable"] ? 1 : 0
  url   = "https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml"
}

# Parse ALB CRDs YAML content
locals {
  alb_crds_yaml = var.alb_config["enable"] ? split("---", data.http.alb_crds[0].body) : null
}

# Create a Kubernetes Service Account for the ALB
resource "kubernetes_service_account" "alb" {
  # Conditional creation based on the enable flag in alb_config
  count = var.alb_config["enable"] ? 1 : 0
  metadata {
    name      = "${var.project_name}-${var.env}-alb"
    namespace = kubectl_manifest.features_ns.name
  }
  depends_on = [
    kubectl_manifest.features_ns
  ]
}

# Apply ALB CRDs to the Kubernetes cluster
resource "kubectl_manifest" "alb_crds" {
  # Conditional creation based on the enable flag in alb_config
  count     = var.alb_config["enable"] ? length(local.alb_crds_yaml) : 0
  yaml_body = local.alb_crds_yaml[count.index]
  depends_on = [
    kubectl_manifest.features_ns
  ]
}

# Deploy the ALB Helm chart to manage the Application Load Balancer
resource "helm_release" "alb" {
  # Conditional creation based on the enable flag in alb_config
  count        = var.alb_config["enable"] ? 1 : 0
  name         = "aws-alb"
  chart        = "aws-load-balancer-controller"
  repository   = "https://aws.github.io/eks-charts"
  version      = var.alb_config["helmChartVersion"]
  force_update = true
  namespace    = kubectl_manifest.features_ns.name

  # Conditional inclusion of values file if provided in alb_config
  values = lookup(var.alb_config, "helm_values_file", "") != "" ? ["${file("${var.alb_config["helm_values_file"]}")}"] : []

  # Set Helm chart values
  set {
    name  = "autoDiscoverAwsRegion"
    value = "true"
  }
  set {
    name  = "autoDiscoverAwsVpcID"
    value = "true"
  }
  set {
    name  = "clusterName"
    value = var.cluster_name
    # value = data.aws_eks_cluster.default.id
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.alb[0].metadata[0].name
  }

  # Ensure the ALB Helm release depends on the creation of the ALB service account
  depends_on = [
    kubernetes_service_account.alb,
    kubectl_manifest.alb_crds,
    kubectl_manifest.features_ns
  ]
}
