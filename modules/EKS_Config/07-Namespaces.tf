# Create Kubernetes namespaces
resource "kubernetes_namespace_v1" "namespaces" {
  # Create a namespace for each entry in namespaces_config, excluding empty keys
  for_each = { for key, value in var.namespaces_config : key => value if key != "" }

  metadata {
    name        = each.key
    annotations = each.value.annotations
    labels      = each.value.labels
  }
}

# Create a namespace "features" with specific labels and annotations
resource "kubectl_manifest" "features_ns" {
  yaml_body = <<-EOF
apiVersion: v1
kind: Namespace
metadata:
  name: "features"
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/warn: restricted
EOF
}

# Create labels for existing namespaces
resource "kubernetes_labels" "ns_labels" {
  # Create labels for each entry in labels_config, excluding empty keys
  for_each = { for key, value in var.labels_config : key => value if key != "" }

  api_version = "v1"
  kind        = "Namespace"
  force       = true

  metadata {
    name = each.key
  }

  labels = each.value
}
