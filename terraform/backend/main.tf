// TerraForm state-lock setup

provider "aws" {
    region = var.aws_region
    profile = "cep-7-admin"
}

resource "aws_s3_bucket" "tf-state" {
    bucket = "cep-7-tf-state"
    tags = {
        Name = "terraform-state-lock"
        Environment = "dev"
    }
}

resource "aws_s3_bucket_versioning" "tf-state-versioning" {
    bucket = aws_s3_bucket.tf-state.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_dynamodb_table" "tf-state-dynamo" {
    name = "terraFormStateLock"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
    tags = {
        Name = "terraform-state-lock"
        Environment = "dev"
    }
}
