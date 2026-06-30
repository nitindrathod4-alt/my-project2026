terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.26"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

##########################
# VARIABLES
##########################

variable "cluster_name" {
  type    = string
  default = "my-cluster"
}

##########################
# DEFAULT VPC
##########################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

##########################
# EKS CLUSTER ROLE
##########################

resource "aws_iam_role" "eks_cluster_role" {

  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "eks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {

  role       = aws_iam_role.eks_cluster_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

}

##########################
# NODE ROLE
##########################

resource "aws_iam_role" "node_role" {

  name = "eks-node-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {

  count = 3

  role = aws_iam_role.node_role.name

  policy_arn = element([

    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",

    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",

    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

  ], count.index)

}

##########################
# EKS CLUSTER
##########################

resource "aws_eks_cluster" "mycluster" {

  name = var.cluster_name

  role_arn = aws_iam_role.eks_cluster_role.arn

  version = "1.33"

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator"
  ]

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  tags = {

    Environment = "Dev"

    Project = "EKS"

  }

  depends_on = [

    aws_iam_role_policy_attachment.eks_cluster_policy

  ]

}

##########################
# EKS ADDONS
##########################

resource "aws_eks_addon" "coredns" {

  cluster_name = aws_eks_cluster.mycluster.name

  addon_name = "coredns"

}

resource "aws_eks_addon" "kube_proxy" {

  cluster_name = aws_eks_cluster.mycluster.name

  addon_name = "kube-proxy"

}

resource "aws_eks_addon" "vpc_cni" {

  cluster_name = aws_eks_cluster.mycluster.name

  addon_name = "vpc-cni"

}

##########################
# NODE GROUP
##########################

OBOBresource "aws_eks_node_group" "nodegroup" {
OB
  cluster_name = aws_eks_cluster.mycluster.name
OB
  node_group_name = "default-node-group"
OBOB
OBOBOB  node_role_arn = aws_iam_role.node_role.arn
OB
  subnet_ids = data.aws_subnets.default.ids

OB  instance_types = ["c7i-flex.large"]
OBOBOB
OB  capacity_type = "ON_DEMAND"

OB  disk_size = 20
OB
  scaling_config {
OBOB
OB    desired_size = 1

OB    min_size = 1

    max_size = 3
OBOB
  }

  tags = {

    Name = "WorkerNodes"
OB
    Environment = "Dev"

  }

  depends_on = [

    aws_iam_role_policy_attachment.node_policies

  ]

}

##########################
# OUTPUTS
##########################

output "cluster_name" {

  value = aws_eks_cluster.mycluster.name

}

output "cluster_endpoint" {

  value = aws_eks_cluster.mycluster.endpoint

}

output "cluster_version" {

  value = aws_eks_cluster.mycluster.version

}

output "cluster_security_group" {

  value = aws_eks_cluster.mycluster.vpc_config[0].cluster_security_group_id

}
