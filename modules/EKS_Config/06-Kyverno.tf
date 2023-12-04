# Deploy Kyverno using Helm
resource "helm_release" "kyverno" {
  # Conditional creation based on the enable flag in kyverno_config
  count      = var.kyverno_config["enable"] ? 1 : 0
  name       = "${var.project_name}-kyverno"
  chart      = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  version    = var.kyverno_config["helmChartVersion"]
  namespace  = kubectl_manifest.features_ns.name
  values     = lookup(var.kyverno_config, "helm_values_file", "") != "" ? ["${file("${var.kyverno_config["helm_values_file"]}")}"] : []
}
