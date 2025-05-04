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

module "kinesis_pipeline" {
  source = "../../modules/aws-kinesis"

  environment                     = "dev"
  kinesis_stream_name             = "orders-stream"
  data_lake                       = "data_lake"
  data_lake_prefix_firehose       = "landing_zone/firehose_stream"
  data_lake_error_prefix_firehose = "landing_zone/firehose_stream_errors"
}
