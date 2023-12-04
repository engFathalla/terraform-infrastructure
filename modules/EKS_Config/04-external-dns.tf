/*******************************************/
/*             external-dns                */
/*******************************************/

# Create an IAM policy for external-dns
resource "aws_iam_policy" "external_dns" {
  # Conditional creation based on the enable flag in external_dns_config
  count  = var.external_dns_config["enable"] ? 1 : 0
  name   = "${var.project_name}-${var.env}-external_dns"
  policy = file("Policies/external-dns-iam-policy.json")
}

# Attach the external-dns IAM policy to specified IAM roles
resource "aws_iam_role_policy_attachment" "external_dns_general" {
  # Conditional creation based on the enable flag in external_dns_config
  for_each   = var.external_dns_config["enable"] ? var.eks_managed_node_groups : {}
  role       = split("/", var.eks_managed_node_groups[each.key]["iam_role_arn"])[1]
  policy_arn = aws_iam_policy.external_dns[0].arn
}

# Deploy external-dns using Helm
resource "helm_release" "dns" {
  # Conditional creation based on the enable flag in external_dns_config
  count      = var.external_dns_config["enable"] ? 1 : 0
  name       = "aws-dns"
  chart      = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  version    = var.external_dns_config["helmChartVersion"]
  namespace  = kubectl_manifest.features_ns.name
  values     = lookup(var.external_dns_config, "helm_values_file", "") != "" ? ["${file("${var.external_dns_config["helm_values_file"]}")}"] : []
}
