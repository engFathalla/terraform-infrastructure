# Network Terraform Module 🔥

This Terraform module sets up a network infrastructure including a VPC, subnets, internet gateway, and NAT gateways.

## Inputs

| Variable               | Type     | Required/Optional | Description                                              |
| ---------------------- | -------- | ------------------ | -------------------------------------------------------- |
| `cidr_vpc`             | `string` | **Required**       | CIDR block for the VPC.                                   |
| `project_name`         | `string` | **Required**       | Name of the project for resource naming.                  |
| `env`                  | `string` | **Required**       | Environment identifier used in resource names.           |
| `tags`                 | `map(any)` | **Required**    | Map of Default Tags.                                      |
| `tag_subnets_k8s_public` | `map(any)` | **Optional**   | Map of tags for Kubernetes public subnets. Default is an empty map. |
| `tag_subnets_k8s_private` | `map(any)` | **Optional**  | Map of tags for Kubernetes private subnets. Default is an empty map. |


## Outputs

| Output                      | Description                                              |
| --------------------------- | -------------------------------------------------------- |
| `vpc_owner_id`              | The owner ID of the VPC.                                  |
| `vpc_id`                    | The ID of the VPC.                                        |
| `private_subnets`           | IDs of all Private subnets.                               |
| `public_subnets`            | IDs of all Public subnets.                                |
| `private_routing_tables_id` | IDs of private routing tables.                            |
| `eks_node_group_sg_id`      | ID of the security group for the EKS node group.          |
