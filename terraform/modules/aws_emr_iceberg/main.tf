data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# GLUE CATALOG ###
resource "aws_glue_catalog_database" "bronze" {
    name = "bronze"
}

resource "aws_glue_catalog_database" "silver" {
    name = "silver"
}

resource "aws_glue_catalog_database" "gold" {
    name = "gold"
}

# IAM #############
### EMR
data "aws_iam_policy_document" "emr_assume_role" {
    statement {
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = ["elasticmapreduce.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "emr_iceberg_role" {
    name = "${var.environment}-emr-role"
    assume_role_policy = data.aws_iam_policy_document.emr_assume_role.json
}

resource "aws_iam_role_policy_attachment" "emr_service_policy" {
  role       = aws_iam_role.emr_iceberg_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role_policy_attachment" "emr_passrole" {
  role       = aws_iam_role.emr_iceberg_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess" # consider custom minimal passrole policy
}


### EC2-PROFILE
data "aws_iam_policy_document" "ec2_profile_assume_role" {
    statement {
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "emr_ec2_profile_role" {
    name = "${var.environment}-emr-ec2-profile-role"
    assume_role_policy = data.aws_iam_policy_document.ec2_profile_assume_role.json
}

data "aws_iam_policy_document" "emr_ec2_attach_policies" {
    statement {
        sid = "GlueCatalogAccess"
        effect = "Allow"
        resources = [
            "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
            "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/bronze",
            "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/silver",
            "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/gold",
            "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*"
            ]

        actions = [
            "glue:GetDatabase",
            "glue:GetDatabases",
            "glue:CreateDatabase",
            "glue:GetTable",
            "glue:GetTables",
            "glue:CreateTable",
            "glue:UpdateTable",
            "glue:DeleteTable"
        ]
    }
    statement {
        sid = "S3Access"
        effect = "Allow"
        resources = [
            "arn:aws:s3:::${var.s3_data_lake_id}/${var.data_lake_prefix_firehose}",
            "arn:aws:s3:::${var.s3_data_lake_id}/${var.data_lake_prefix_firehose}/*",
            "arn:aws:s3:::${var.s3_data_lake_id}/bronze",
            "arn:aws:s3:::${var.s3_data_lake_id}/bronze/*",
            "arn:aws:s3:::${var.s3_data_lake_id}/silver",
            "arn:aws:s3:::${var.s3_data_lake_id}/silver/*",
            "arn:aws:s3:::${var.s3_data_lake_id}/gold",
            "arn:aws:s3:::${var.s3_data_lake_id}/gold/*"
        ]
        actions = [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:GetBucketLocation"
        ]
    }

    statement {
        effect = "Allow"
        resources = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/emr/logs/*",
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/emr/logs/*:log-stream:*"
        ]
        actions = [
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams"
        ]
    }
}

resource "aws_iam_role_policy" "emr_ec2_policy" {
    name = "emr-ec2-profile-policy"
    role = aws_iam_role.emr_ec2_profile_role.name
    policy = data.aws_iam_policy_document.emr_ec2_attach_policies.json
}

resource "aws_iam_role_policy_attachment" "emr_ec2_ssm" {
  role       = aws_iam_role.emr_ec2_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "emr_ec2_profile" {
    role = aws_iam_role.emr_ec2_profile_role.name
}

# OBSERVABILITY ###
resource "aws_cloudwatch_log_group" "emr_logs" {
  name              = "/emr/logs"
  retention_in_days = 7
}


# EMR #############
resource "aws_emr_cluster" "iceberg_cluster" {
    name = "iceberg_clsuter"
    release_label = "emr-7.8.0"
    service_role = aws_iam_role.emr_iceberg_role.arn

    applications = ["Spark"]

    ec2_attributes {
        subnet_id = var.emr_subnet_id
        emr_managed_master_security_group = var.emr_master_sg 
        emr_managed_slave_security_group = var.emr_core_sg
        instance_profile = aws_iam_instance_profile.emr_ec2_profile.arn
    }
    # NOTE: EBS is disabled on purpose for demonstration only. Consider adding back in to maintain
    # Spark performance
    master_instance_group {
        instance_type = "m4.large"

        dynamic "ebs_config" {
            for_each = var.enable_ebs_storage ? [1] : []
            content {
                size = var.ebs_volume_size
                type = var.ebs_volume_type
                volumes_per_instance = 1
            }
        }
    }

    core_instance_group {
        instance_type = "c4.large"
        instance_count = 2

        dynamic "ebs_config" {
            for_each = var.enable_ebs_storage ? [1] : []
            content {
            size                 = var.ebs_volume_size
            type                 = var.ebs_volume_type
            volumes_per_instance = 1
            }
        }
    }

    # NOTE: Monitor whether emr-7.8.0 includes all that is necessary for Iceberg out of the box!
    # bootstrap_action {
    #     name = ""
    #     path = ""
    # }

    log_uri = "s3://${var.s3_data_lake_id}/emr/logs"

    configurations_json = jsonencode([
    {
        "Classification": "spark-defaults",
        "Properties": {
        "spark.sql.catalog.bronze": "org.apache.iceberg.spark.SparkCatalog",
        "spark.sql.catalog.bronze.catalog-impl": "org.apache.iceberg.aws.glue.GlueCatalog",
        "spark.sql.catalog.bronze.warehouse": "s3://${var.s3_data_lake_id}/bronze/",
        "spark.sql.catalog.bronze.io-impl": "org.apache.iceberg.aws.s3.S3FileIO",

        "spark.sql.catalog.silver": "org.apache.iceberg.spark.SparkCatalog",
        "spark.sql.catalog.silver.catalog-impl": "org.apache.iceberg.aws.glue.GlueCatalog",
        "spark.sql.catalog.silver.warehouse": "s3://${var.s3_data_lake_id}/silver/",
        "spark.sql.catalog.silver.io-impl": "org.apache.iceberg.aws.s3.S3FileIO",

        "spark.sql.catalog.gold": "org.apache.iceberg.spark.SparkCatalog",
        "spark.sql.catalog.gold.catalog-impl": "org.apache.iceberg.aws.glue.GlueCatalog",
        "spark.sql.catalog.gold.warehouse": "s3://${var.s3_data_lake_id}/gold/",
        "spark.sql.catalog.gold.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
        }
    }
    ]
    )

    auto_termination_policy {
        idle_timeout = 3600 # seconds == 1 hour
    }

    tags = {
        Project     = "cep-7"
        Environment = var.environment
        Owner       = "YourName"
        CostCenter  = "BigData"
    }

}


# # EMR STEPS with automatic triggers #############
# resource "aws_emr_step" "raw_to_bronze" {
#   cluster_id = aws_emr_cluster.iceberg_cluster.id
#   name       = "RawToBronzeIngestion"
#   action_on_failure = "CONTINUE"

#   hadoop_jar_step {
#     jar = "command-runner.jar"
#     args = [
#       "spark-submit",
#       "--deploy-mode", "cluster",
#       "--conf", "spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog",
#       "--conf", "spark.sql.catalog.glue_catalog.warehouse=s3://${var.s3_data_lake_id}/bronze",
#       "--conf", "spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog",
#       "s3://${var.s3_static}/scripts/raw_to_bronze.py"
#     ]
#   }
# }

resource "aws_cloudwatch_event_rule" "run_emr_step_every_5min" {
  name                = "run-emr-step-every-5min"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_iam_role" "lambda_emr_trigger" {
  name = "lambda-emr-trigger-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "attach-basic-lambda"
  roles      = [aws_iam_role.lambda_emr_trigger.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_emr_permissions" {
  name = "lambda-emr-permissions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "elasticmapreduce:AddJobFlowSteps",
          "elasticmapreduce:DescribeCluster",
          "elasticmapreduce:ListClusters"
        ],
        Resource = "*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_emr_attach" {
  name       = "lambda-emr-attach"
  roles      = [aws_iam_role.lambda_emr_trigger.name]
  policy_arn = aws_iam_policy.lambda_emr_permissions.arn
}

resource "aws_lambda_function" "trigger_emr_step" {
    s3_bucket = var.s3_static
  s3_key         = "scripts/lambda_emr_trigger.zip"  
  function_name    = "TriggerEMRStep"
  role             = aws_iam_role.lambda_emr_trigger.arn
  handler          = "lambda_emr_trigger.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = filebase64sha256("../../../lambda_emr_trigger.zip")
  timeout          = 30

  environment {
    variables = {
        CLUSTER_ID = aws_emr_cluster.iceberg_cluster.id 
        PATH_TO_SCRIPT = "${var.s3_static}/scripts/raw_to_bronze.py"
    }
  }
}


resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.run_emr_step_every_5min.name
  target_id = "TriggerEMRStep"
  arn       = aws_lambda_function.trigger_emr_step.arn
}

resource "aws_lambda_permission" "allow_cwe_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_emr_step.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.run_emr_step_every_5min.arn
}
