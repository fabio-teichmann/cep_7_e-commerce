output "eks_cluster_name" {
    value = module.eks.cluster_name 
}

output "kinesis_stream_name" {
    value = module.kinesis_pipeline.kinesis_stream_name
}

output "eks_irsa_role_arn" {
    value = aws_iam_role.eks_irsa_role.arn
}