variable "domain" {
    default = "product_catalog"
}

variable "eks_app_role_arn" {
    description = "ARN of the EKS cluster role for IRSA"
    type = string
}
