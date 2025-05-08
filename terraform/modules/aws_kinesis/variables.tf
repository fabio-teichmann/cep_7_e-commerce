variable "environment" {
    type = string
    default = "dev"
}

variable "kinesis_stream_name" {
    type = string
    default = "order_stream"
}

variable "data_lake" {
    type = string
    default = "cep-7-data_lake"
}

variable "data_lake_prefix_firehose" {
    type = string
    default = "landing_zone/firehose_stream"
}

variable "data_lake_error_prefix_firehose" {
    type = string
    default = "landing_zone/firehose_stream_errors"
}