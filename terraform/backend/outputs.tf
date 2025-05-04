// to generate a `backend.config` file for use in project
output "bucket" {
    value = aws_s3_bucket.tf-state.bucket 
}

output "key"{
    value = "environments/dev/terraform.tfstate"
}

output "region" {
    value = var.aws_region
}

output "dynamodb_table" {
    value = aws_dynamodb_table.tf-state-dynamo.name
}

output "encrypt" {
    value = true
}