# Terraform AWS EKS Module 🔥

This Terraform module deploys an Amazon EKS (Elastic Kubernetes Service) cluster on AWS. It provides a flexible and reusable way to create and manage EKS clusters, including associated resources like worker nodes, networking components, and various add-ons.

## Variables ✨

| Variable                  | Type                                      | Required/Optional | Default Value  | Description                                                 |
| :------------------------ | :---------------------------------------- | :----------------- | :------------- | :---------------------------------------------------------- |
| `cluster_name`            | `string`                                  | **Required**      |                | The name of the Amazon EKS cluster                          |
| `cluster_version`         | `string`                                  | **Required**      |                | The desired Kubernetes version for the Amazon EKS cluster    |
| `cluster_vpc`             | `string`                                  | **Required**      |                | The ID of the VPC in which to create the Amazon EKS cluster  |
| `project_name`            | `string`                                  | **Required**      |                | The name of the project                                     |
| `eks_managed_node_groups` | `map(any)`                                | **Required**      |                | Map of node group configurations                             |
| `aws_auth_roles`          | `list(object({ rolearn = string, username = string, groups = list(string) }))` | **Required** |              | List of AWS auth roles                                       |
| `private_subnet_1a`       | `string`                                  | **Required**      |                | The ID of the first private subnet                           |
| `private_subnet_1b`       | `string`                                  | **Required**      |                | The ID of the second private subnet                          |
| `private_subnet_1c`       | `string`                                  | **Required**      |                | The ID of the third private subnet                           |
| `env`                     | `string`                                  | **Required**      |                | The environment (e.g., dev, stage, prod)                    |
| `tags`                    | `map(string)`                            | **Required**      |                | Tags to apply to all resources created by this module       |
| `eks_node_group_sg_id`    | `string`                                  | **Required**      |                | The ID of the security group for the Amazon EKS worker nodes |
| `ami_id`                  | `string`                                  | Optional           | `""`           | The ID of a custom Amazon Machine Image (AMI) to use for the worker nodes |
| `cluster_addons`          | `any`                                     | Optional           | `{ coredns: { most_recent: true }, kube-proxy: { most_recent: true }, vpc-cni: { most_recent: true }, aws-ebs-csi-driver: { most_recent: true } }` | Addons to deploy in the Amazon EKS cluster                  |

### Outputs ✨

| Output                               | Description                                               |
| :----------------------------------- | :-------------------------------------------------------- |
| `node_security_group_id`             | ID of the security group for the EKS worker nodes         |
| `cluster_security_group_id`          | ID of the security group for the EKS cluster              |
| `eks_cluster_status`                 | Status of the EKS cluster                                 |
| `oidc_provider_arn`                  | Amazon Resource Name (ARN) of the OIDC provider for the EKS cluster |
| `oidc_provider`                      | OIDC provider URL for the EKS cluster                     |
| `cluster_oidc_issuer_url`            | OIDC issuer URL for the EKS cluster                        |
| `cluster_name`                       | Name of the EKS cluster                                   |
| `cluster_endpoint`                   | Endpoint URL for the EKS cluster                          |
| `cluster_certificate_authority_data` | Certificate authority data for the EKS cluster            |
| `eks_managed_node_groups`            | Information about the managed node groups in the EKS cluster |


## Usage

```hcl
module "cluster_eks" {
  source = "./path/to/cloudfront_policies"
  cluster_name            = "demo_cluster"
  cluster_version         = "1.27"
  project_name            = "my-project"
  env                     = "PROD"
  cluster_vpc             = module.network.vpc_id
  private_subnet_1a       = module.network.private_subnet_1
  private_subnet_1b       = module.network.private_subnet_2
  private_subnet_1c       = module.network.private_subnet_3
  eks_node_group_sg_id    = module.network.eks_node_group_sg_id
  eks_managed_node_groups = {
    "demo-cluster" = {
      desired_size             = 1
      min_size                 = 1
      max_size                 = 10
      use_custom_launch_template = true
      enable_bootstrap_user_data = true
      labels = {
        role = "demo-cluster"
      }
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 60
            volume_type           = "gp2"
            iops                  = 0
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      taints = {}
      tags = {
        Project     = "demo-project"
        Environment = "PROD"
      }
    }
  }
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::<AWS Account ID>:role/Administrator"
      username = "eks-web-console"
      groups   = ["dc:cluster:admin"]
    }
  ]
  tags = var.tags
}
```

