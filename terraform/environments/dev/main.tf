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
      region = var.aws_region
    }
  }
  required_version = ">= 1.3.0"
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

  # enable_nat_gateway = true
  # single_nat_gateway = true

  tags = {
    Environment = "dev"
  }
}

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "19.21.0"  # Latest stable as of May 2025

#   cluster_name    = "webshop-eks"
#   cluster_version = "1.29"
#   subnet_ids      = module.vpc.public_subnets
#   vpc_id          = module.vpc.vpc_id

#   enable_irsa = true

#   eks_managed_node_groups = {
#     default = {
#       min_size     = 1
#       max_size     = 3
#       desired_size = 2

#       instance_types = ["t3.medium"]
#       capacity_type  = "SPOT"
#     }
#   }

#   cluster_endpoint_public_access       = true
#   cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # restrict in production

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }



# provider "helm" {
#   kubernetes {
#     config_path = "~/.kube/config"
#   }
# }

# resource "helm_release" "webshop" {
#   name       = "webshop"
#   chart      = "${path.module}/helm-charts/webshop"
#   namespace  = "default"
#   create_namespace = false

#   set {
#     name  = "image.repository"
#     value = "${var.image_repo}/webshop"
#   }

#   set {
#     name  = "image.tag"
#     value = "latest"
#   }

#   set {
#     name  = "service.type"
#     value = "LoadBalancer"
#   }

#   depends_on = [module.eks]
# }



# module "kinesis_pipeline" {
#   source = "../../modules/aws-kinesis"

#   environment                     = "dev"
#   kinesis_stream_name             = "orders-stream"
#   data_lake                       = "data_lake"
#   data_lake_prefix_firehose       = "landing_zone/firehose_stream"
#   data_lake_error_prefix_firehose = "landing_zone/firehose_stream_errors"
# }
