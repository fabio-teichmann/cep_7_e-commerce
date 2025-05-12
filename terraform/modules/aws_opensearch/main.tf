data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "open_search_access" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.eks_app_role_arn]
    }

    actions   = ["es:*"]
    resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain}/*"]
  }
}

resource "aws_opensearch_domain" "product_catalog" {
    domain_name = var.domain
    engine_version = "OpenSearch_1.0"

    cluster_config {
        instance_type = "r4.large.search"
        instance_count = 1
    }

    access_policies = data.aws_iam_policy_document.open_search_access.json

    tags = {
        Name = "openSearchProductCatalog"
        Environment = "dev"
    }
}