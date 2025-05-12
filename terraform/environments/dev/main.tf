terraform {
  backend "s3" {
    bucket         = ""
    key            = ""
    region         = ""
    dynamodb_table = ""
    encrypt        = ""
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  map_public_ip_on_launch = true
  # enable_nat_gateway = true
  # single_nat_gateway = true

  tags = {
    Environment = "dev"
  }
}

# IAM for EKS #########################
data "aws_eks_cluster" "webshop" {
  name = module.eks.cluster_name
  depends_on = [ module.eks ]
}
data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.webshop.identity[0].oidc[0].issuer
  # url = module.eks.main.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eks_irsa_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values = ["system:serviceaccount:${var.eks_namespace}:${var.eks_svc_acc_name}"]
    }
  }
}

resource "aws_iam_role" "eks_irsa_role" {
  name = "eks-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.eks_irsa_assume_role.json
}

data "aws_iam_policy_document" "eks_irsa_attach_roles" {
  statement {
    effect = "Allow"
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords",
      "es:ESHttp*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "eks_irsa_policy" {
  name = "eks-irsa-policies"
  policy = data.aws_iam_policy_document.eks_irsa_attach_roles.json 
}

resource "aws_iam_role_policy_attachment" "attach_kinesis" {
  role = aws_iam_role.eks_irsa_role.name
  policy_arn = aws_iam_policy.eks_irsa_policy.arn
}


# EKS Cluster ########################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"  # Latest stable as of May 2025

  cluster_name    = "webshop-eks"
  cluster_version = "1.32"
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }

  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # restrict in production

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.node_security_group_id
}


# KINESIS ###################
resource "random_string" "bucket_suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

module "kinesis_pipeline" {
  source = "../../modules/aws_kinesis"

  environment                     = "dev"
  kinesis_stream_name             = "orders-stream"
  data_lake                       = "cep-7-data-lake-${random_string.bucket_suffix.result}"
  data_lake_prefix_firehose       = "landing_zone/firehose_stream"
  data_lake_error_prefix_firehose = "landing_zone/firehose_stream_errors"
}


# OPENSEARCH ################
module "opensearch" {
  source = "../../modules/aws_opensearch"

  domain = "product_catalog"
  eks_app_role_arn = module.eks.eks_irsa_role.arn
}