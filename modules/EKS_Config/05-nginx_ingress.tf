# Deploy nginx-ingress using Helm
resource "helm_release" "nginx-ingress" {
  # Conditional creation based on the enable flag in nginx_config
  count      = var.nginx_config["enable"] ? 1 : 0
  name       = "${var.project_name}-${var.env}"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = var.nginx_config["helmChartVersion"]
  namespace  = "kube-system"
  values     = lookup(var.nginx_config, "helm_values_file", "") != "" ? ["${file("${var.nginx_config["helm_values_file"]}")}"] : []

  # Set annotations for the nginx-ingress controller service
  set {
    name  = "controller.service.annotations.service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags"
    value = "Confidentiality=${var.tags["Confidentiality"]},Project=${var.tags["Project"]},SecurityZone=${var.tags["SecurityZone"]},Environment=${var.tags["Environment"]},TaggingVersion=${var.tags["TaggingVersion"]},ManagedBy=${var.tags["ManagedBy"]}"
  }

  set {
    name  = "controller.service.annotations.service.beta.kubernetes.io/aws-load-balancer-name"
    value = "${var.tags["Project"]}-nginx-ingress"
  }
}
