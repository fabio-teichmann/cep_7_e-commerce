variable "environment" {
    type = string
    default = "dev"
}

variable "s3_data_lake_id" {
    type = string
    description = "id of the data lake bucket created as landing zone for Kinesis Streams and Firehose"
}

variable "s3_static" {
  type = string
  default = "cep-7-static"
}

variable "data_lake_prefix_firehose" {
    type = string
    description = "the prefix used in Kinesis to write data to the landing zone"
}

variable "emr_subnet_id" {
    type = string
}

variable "emr_master_sg" {
    type = string
}

variable "emr_core_sg" {
    type = string
}

variable "enable_ebs_storage" {
  description = "Whether to attach additional EBS storage to EMR instances"
  type        = bool
  default     = false
}

variable "ebs_volume_size" {
  description = "Size of each EBS volume (in GB)"
  type        = number
  default     = 100
}

variable "ebs_volume_type" {
  description = "Type of EBS volume to use"
  type        = string
  default     = "gp3"
}