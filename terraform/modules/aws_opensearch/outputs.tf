output "opensearch_domain" {
    value = aws_opensearch_domain.product_catalog.domain_name
}

output "opensearch_endpoint" {
  value = aws_opensearch_domain.product_catalog.endpoint
}
