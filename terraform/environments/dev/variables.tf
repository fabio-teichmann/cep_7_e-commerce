variable "aws_region" {
    type = string
    default = "us-east-1"
}

variable "image_repo" {
    type = string
}

variable "eks_namespace" {
    type = string
    default = "default"
}

variable "eks_svc_acc_name" {
    type = string
}