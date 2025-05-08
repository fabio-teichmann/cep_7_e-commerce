data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "firehose_assume_role" {
    statement {
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["firehose.amazonaws.com"]
        }

        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "firehose" {
  name = "${var.environment}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

data "aws_iam_policy_document" "kinesis_attach_policies" {
    statement {
        effect = "Allow"
        resources = [aws_kinesis_stream.order_stream.arn]
        actions = [
            "kinesis:DescribeStream",
            "kinesis:GetShardIterator",
            "kinesis:GetRecords",
            "kinesis:ListShards"
        ]
    }
    statement {
        effect = "Allow" 
        resources = [
            "arn:aws:s3:::${aws_s3_bucket.data_lake.id}/${var.data_lake_prefix_firehose}",
            "arn:aws:s3:::${aws_s3_bucket.data_lake.id}/${var.data_lake_prefix_firehose}/*",
            "arn:aws:s3:::${aws_s3_bucket.data_lake.id}/${var.data_lake_error_prefix_firehose}",
            "arn:aws:s3:::${aws_s3_bucket.data_lake.id}/${var.data_lake_error_prefix_firehose}/*"
        ]
        actions = [
            "s3:PutObject",
            "s3:GetBucketLocation",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:AbortMultipartUpload",
            "s3:PutObjectTagging"
        ]
    }
    statement {
        effect = "Allow"
        resources = ["*"]
        actions = ["logs:PutLogEvents"]
    }
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose_access_policy"
  role = aws_iam_role.firehose.name

  policy = data.aws_iam_policy_document.kinesis_attach_policies.json
}


resource "aws_kinesis_stream" "order_stream" {
    name = var.kinesis_stream_name
    shard_count = 1

    shard_level_metrics = [
        "IncomingBytes",
        "OutgoingBytes",
    ]

    stream_mode_details {
        stream_mode = "PROVISIONED"
    }
}

resource "aws_s3_bucket" "data_lake" {
  bucket        = var.data_lake
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake_life_cycle" {
    bucket = aws_s3_bucket.data_lake.id
    rule {
        id = "raw_data_purge"
        status = "Enabled"

        filter {
            prefix = "${var.data_lake_prefix_firehose}/"
        }

        expiration {
            days = 30
        }
    }

    rule {
        id = "raw_data_error_purge"
        status = "Enabled"

        filter {
            prefix = "${var.data_lake_error_prefix_firehose}/"
        }

        expiration {
            days = 90
        }
    }
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_to_lake" {
    name = "kinesis_firehose_to_s3_from_stream"
    destination = "extended_s3"

    kinesis_source_configuration {
        kinesis_stream_arn = aws_kinesis_stream.order_stream.arn
        role_arn = aws_iam_role.firehose.arn
    }
    extended_s3_configuration {
        role_arn           = aws_iam_role.firehose.arn
        bucket_arn         = aws_s3_bucket.data_lake.arn
        compression_format = "UNCOMPRESSED"
        prefix = "${var.data_lake_prefix_firehose}/!{timestamp:yyyy/MM/dd}/"
        error_output_prefix = "${var.data_lake_error_prefix_firehose}/!{timestamp:yyyy/MM/dd}/!{firehose:error-output-type}/"
    }
}
