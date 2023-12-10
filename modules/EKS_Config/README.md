# Terraform EKS Components Module

This Terraform module deploys and configures various optional components such as namespaces, Application Load Balancer (ALB), Nginx Ingress Controller, Cluster Autoscaler, External DNS, and Kyverno.

## Usage

### Inputs

The following variables can be customized to fit your deployment needs:

| Variable                   | Type                 | Required/Optional         | Default Value             | Description                                 |
| :------------------------- | :------------------- | :------------------------ | :------------------------ | :------------------------------------------ |
| `project_name`             | `string`             | **Required**              |                           | The name of the project                     |
| `env`                      | `string`             | **Required**              |                           | The environment of the deployment          |
| `tags`                     | `map(string)`        | **Required**              |                           | Map of tags to be applied to AWS resources |
| `cluster_name`             | `string`             | **Required**              |                           | Name of the EKS cluster                     |
| `eks_managed_node_groups`  | `map(any)`           | **Required**              |                           | Map of node group configurations           |
| `namespaces_config`        | `map(object({labels = optional(map(string)), annotations = optional(map(string))}))` | **Optional**  | `{ "" = { labels = {}, annotations = {} } }` | Configuration for Kubernetes namespaces    |
| `labels_config`            | `any`                | **Optional**              | `{}`                      | Additional labels for Kubernetes namespaces|
| `alb_config`               | `any`                | **Optional**              | `{ enable = false, helmChartVersion = "1.6.2" }` | Configuration for AWS Application Load Balancer|
| `nginx_config`             | `any`                | **Optional**              | `{ enable = false, nginx_helmChartVersion = "1.6.2", helm_values_file = "" }` | Configuration for NGINX Ingress Controller|
| `autoscaler_config`        | `any`                | **Optional**              | `{ enable = false, helmChartVersion = "1.6.2", helm_values_file = "" }` | Configuration for Cluster Autoscaler      |
| `external_dns_config`      | `any`                | **Optional**              | `{ enable = false, helmChartVersion = "6.28.5", helm_values_file = "" }` | Configuration for External DNS            |
| `kyverno_config`           | `any`                | **Optional**              | `{ enable = false, helmChartVersion = "3.1.0", helm_values_file = "" }` | Configuration for Kyverno Policy Engine   |


#### General Configuration

- `project_name` (string): The name of the project.
- `env` (string): The environment of the deployment (e.g., dev, prod).
- `tags` (map[string]): A map of tags to be applied to AWS resources.
- `cluster_name` (string): The name of the EKS cluster.
- `eks_managed_node_groups` (map[any]): Map of configurations for managed node groups in the EKS cluster.


#### Namespaces Configuration

- `namespaces_config` (map[object]): Configuration for Kubernetes namespaces, including labels and annotations.
- `labels_config` (any): Configuration for Kubernetes labels to be applied to existing namespaces.

#### ALB Configuration

- `alb_config` (any): Configuration for deploying an Application Load Balancer (ALB).

#### Nginx Ingress Configuration

- `nginx_config` (any): Configuration for deploying Nginx Ingress Controller.

#### Cluster Autoscaler Configuration

- `autoscaler_config` (any): Configuration for deploying the Kubernetes Cluster Autoscaler.

#### External DNS Configuration

- `external_dns_config` (any): Configuration for deploying External DNS for Kubernetes.

#### Kyverno Configuration

- `kyverno_config` (any): Configuration for deploying Kyverno, a policy engine for Kubernetes.

### Example Usage

```hcl
module "eks_infra" {
  source = "./path/to/eks_components_module"

  project_name            = "my_project"
  env                     = "prod"
  tags                    = { Confidentiality = "C2", Project = "my_project" }
  cluster_name            = "my-eks-cluster"
  eks_managed_node_groups = { "node_group_1" = { /* Node group configurations */ } }

  namespaces_config = {
    "dev" = {
      labels      = { "environment" = "development" }
      annotations = { "example.com/annotation" = "value" }
    },
    "prod" = {
      labels = { "environment" = "production" }
    }
  }

  labels_config = {
    "default" = {
      "app" = "my-app"
    },
    "kube-system" = {
      "k8s-addon" = "kube-system-addon"
    }
  }

  alb_config = {
    enable           = true
    helmChartVersion = "1.6.2"
  }

  nginx_config = {
    enable                 = true
    nginx_helmChartVersion = "1.6.2"
    helm_values_file       = "./nginx_values.yaml"
  }

  autoscaler_config = {
    enable           = true
    helmChartVersion = "1.6.2"
    helm_values_file = "./autoscaler_values.yaml"
  }

  external_dns_config = {
    enable           = true
    helmChartVersion = "6.28.5"
    helm_values_file = "./external_dns_values.yaml"
  }

  kyverno_config = {
    enable           = true
    helmChartVersion = "3.1.0"
    helm_values_file = "./kyverno_values.yaml"
  }
}
```
