output "kinesis_stream_name" {
    value = aws_kinesis_stream.order_stream.name
}
output "data_lake" {
    value = aws_s3_bucket.data_lake.id 
}
output "landing_zone_kfh" {
    value = var.data_lake_prefix_firehose
}
output "landing_zone_kfh_errors" {
    value = var.data_lake_error_prefix_firehose
}
