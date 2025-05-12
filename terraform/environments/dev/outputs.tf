output "eks_cluster_name" {
    value = module.eks.cluster_name 
}

output "kinesis_stream_name" {
    value = module.kinesis_pipeline.kinesis_stream_name
}

output "eks_irsa_role_arn" {
    value = aws_iam_role.eks_irsa_role.arn
}

output "svc_acc_name" {
    value = var.eks_svc_acc_name
}

output "opensearch_domain" {
    value = module.opensearch.opensearch_domain
}

output "opensearch_endpoint" {
  value = module.opensearch.opensearch_endpoint
}
