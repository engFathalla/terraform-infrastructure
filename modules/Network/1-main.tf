data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

##########################################
##################  VPC #################
##########################################

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    { Name = "${var.project_name}_${var.env}" },
    var.tags
  )
}

resource "aws_internet_gateway" "aws_internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { Name = "${var.project_name}_${var.env}_igw" },
    var.tags
  )
}

resource "aws_subnet" "aws_subnet_public" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    { Name = "${var.project_name}_${var.env}_public_subnet_${count.index}" },
    var.tag_subnets_k8s_public,
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { Name = "${var.project_name}_${var.env}_public_rt" },
    var.tags,
  )
}
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.aws_internet_gateway.id

}

resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.aws_subnet_public[*].id, count.index)
  route_table_id = element(aws_route_table.public[*].id, count.index)
}


resource "aws_subnet" "aws_subnet_private_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 4, count.index + 3)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = merge(
    { Name = "${var.project_name}_${var.env}_private_subnet${count.index}" },
    var.tag_subnets_k8s_private,
  )
}

resource "aws_route_table" "aws_route_table_private" {
  vpc_id = aws_vpc.vpc.id
  count  = length(data.aws_availability_zones.available.names)
  tags = merge(
    { Name = "${var.project_name}_${var.env}_private_rt_${count.index}" },
    var.tags
  )
}

resource "aws_route" "private_route_1" {
  route_table_id         = aws_route_table.aws_route_table_private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway[0].id
}
resource "aws_route" "private_route_2" {
  route_table_id         = aws_route_table.aws_route_table_private[1].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway[1].id
}
resource "aws_route" "private_route_3" {
  route_table_id         = aws_route_table.aws_route_table_private[2].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway[2].id
}
resource "aws_route_table_association" "private" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.aws_subnet_private_subnet[count.index].id
  route_table_id = aws_route_table.aws_route_table_private[count.index].id
}

resource "aws_eip" "eipgeneral" {
  count  = length(data.aws_availability_zones.available.names)
  domain = "vpc"
  tags = merge(
    { Name = "${var.project_name}_${var.env}_aws_eip_${count.index}" },
    var.tags,
  )
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = length(data.aws_availability_zones.available.names)
  allocation_id = aws_eip.eipgeneral[count.index].id
  subnet_id     = aws_subnet.aws_subnet_public[count.index].id
  tags = merge(
    { Name = "${var.project_name}_${var.env}_${count.index}" },
    var.tags,
  )
}




resource "aws_security_group" "node_group_sg" {
  # checkov:skip=CKV2_AWS_5: it's been refrenced in external modules
  name_prefix = "${var.project_name}_${var.env}_eks_node_group_sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Allow inbound SSH traffic from CIDR block 10.0.0.0/8"
  }

  tags = merge(
    { Name = "${var.project_name}_${var.env}_node_group_sg" },
    var.tags,
  )
  description = "Security group for EKS node group with SSH access"
}