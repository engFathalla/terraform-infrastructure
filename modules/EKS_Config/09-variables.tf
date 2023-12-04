######## General ########
variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "env" {
  type        = string
  description = "The environment of the deployment (e.g., development, staging, production)."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to be applied to AWS resources."
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster."
}

variable "eks_managed_node_groups" {
  type        = map(any)
  description = "Map of configurations for managed node groups in the EKS cluster."
}
variable "oidc_provider_arn" {
  type = string
}
######## Namespaces ########
variable "namespaces_config" {
  type        = map(object({
    labels      = optional(map(string))
    annotations = optional(map(string))
  }))
  description = "Configuration for Kubernetes namespaces including labels and annotations."
  default     = {
    "" = {
      labels      = {}
      annotations = {}
    }
  }
}

variable "labels_config" {
  type        = any
  description = "Configuration for Kubernetes labels to be applied to existing namespaces."
  default     = {}
}

######## ALB ########
variable "alb_config" {
  type        = any
  description = "Configuration for deploying an Application Load Balancer (ALB)."
  default     = {
    enable           = false
    helmChartVersion = "1.6.2"
  }
}

######## Nginx ########
variable "nginx_config" {
  type        = any
  description = "Configuration for deploying Nginx Ingress Controller."
  default     = {
    enable                 = false
    nginx_helmChartVersion = "1.6.2"
    helm_values_file       = ""
  }
}

######## AutoScaler ########
variable "autoscaler_config" {
  type        = any
  description = "Configuration for deploying the Kubernetes Cluster Autoscaler."
  default     = {
    enable           = false
    helmChartVersion = "1.6.2"
    helm_values_file = ""
  }
}

######## External DNS ########
variable "external_dns_config" {
  type        = any
  description = "Configuration for deploying External DNS for Kubernetes."
  default     = {
    enable           = false
    helmChartVersion = "6.28.5"
    helm_values_file = ""
  }
}

######## Kyverno ########
variable "kyverno_config" {
  type        = any
  description = "Configuration for deploying Kyverno, a policy engine for Kubernetes."
  default     = {
    enable           = false
    helmChartVersion = "3.1.0"
    helm_values_file = ""
  }
}
